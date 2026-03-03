raise 'Ruby 4.0+ is required for Rb::Package' if RUBY_VERSION.to_f < 4.0

require 'rubygems'

module Rb
  module Package
    # Absolute path to this file -- used to skip our own frames in caller_locations.
    THIS_FILE = File.expand_path(__FILE__)

    def import(path)
      box = Ruby::Box.new
      # Inject Prism into the box's isolated namespace using the already-loaded
      # outer-process module.  Ruby::Box::Loader can't load C extensions, but
      # all objects exist in the same Ruby process, so we share the reference.
      # if defined?(Prism)
      #   box.eval(
      #     "Object.const_set(:Prism, ObjectSpace._id2ref(#{Prism.object_id})) unless Object.const_defined?(:Prism)",
      #   )
      # end
      box.require(__FILE__)

      # Resolve relative/absolute file paths; fall back to gem name lookup
      expanded = File.expand_path(path, Dir.pwd)
      if File.exist?(expanded) || File.exist?("#{expanded}.rb")
        box.require(expanded)
      else
        # Gem import: inject transitive load paths into the box first
        gem_require_paths(path).each do |p|
          box.eval("$LOAD_PATH << #{p.inspect}")
        end
        box.require(path)
      end

      begin
        exports = box.const_get(:EXPORTS)
        process_exports(exports)
      rescue NameError
        # Legacy gem with no EXPORTS -- build a lazy proxy module
        build_legacy_proxy(box)
      end
    end

    def export(*args, **kwargs)
      value =
        if kwargs.any? && args.empty?
          kwargs # Multiple exports
        elsif args.size == 1 && kwargs.empty?
          args.first # Single export
        else
          raise ArgumentError,
                'Export takes either a single object or keyword arguments'
        end

      # Sets the EXPORTS constant on the Box's isolated Object namespace
      Object.const_set(:EXPORTS, value)
    end

    private

    def gem_require_paths(name, visited = Set.new)
      return [] if visited.include?(name)

      visited << name
      spec = Gem::Specification.find_by_name(name)
      paths = spec.full_require_paths.dup
      spec.runtime_dependencies.each do |dep|
        paths.concat(gem_require_paths(dep.name, visited))
      end
      paths
    rescue Gem::MissingSpecError
      []
    end

    def build_legacy_proxy(box)
      Module.new do
        define_singleton_method(:const_missing) do |name|
          box.const_get(name)
        rescue NameError
          raise NameError, "uninitialized constant #{name}"
        end

        define_singleton_method(:method_missing) do |name, *args, **kw, &blk|
          box.eval(name.to_s)
        rescue NameError, NoMethodError
          raise NoMethodError, "undefined method '#{name}'"
        end

        define_singleton_method(:respond_to_missing?) { |*, **| true }

        define_singleton_method(:deconstruct_keys) do |keys|
          result =
            if keys
              keys.each_with_object({}) do |key, hash|
                hash[key] = if key.to_s.match?(/\A[A-Z]/)
                  begin
                    box.const_get(key)
                  rescue NameError
                    next
                  end
                else
                  begin
                    box.eval(key.to_s)
                  rescue NameError, NoMethodError
                    next
                  end
                end
              end
            else
              {}
            end
          Rb::Package.auto_promote(result, caller_locations(1, 6))
          result
        end
      end
    end

    def process_exports(exports)
      if exports.is_a?(Hash)
        mod = Module.new
        mod.const_set(:EXPORTS, exports)
        mod.send(:private_constant, :EXPORTS)

        exports.each do |k, v|
          if k.to_s.match?(/\A[A-Z]/)
            mod.const_set(k, v)
          else
            mod.define_singleton_method(k) do |*args, **kw, &blk|
              v.respond_to?(:call) ? v.call(*args, **kw, &blk) : v
            end
          end
        end

        mod.define_singleton_method(:deconstruct_keys) do |keys|
          result = keys ? exports.slice(*keys) : exports.dup
          Rb::Package.auto_promote(result, caller_locations(1, 6))
          result
        end

        mod
      else
        # Single export just returns the object directly
        exports
      end
    end

    # -------------------------------------------------------------------------
    # Constant / variable auto-promotion via symbol targets.
    # These are module-level singleton methods, NOT mixed into Kernel.
    # -------------------------------------------------------------------------

    # Parsed Prism ASTs keyed by absolute file path.
    @ast_cache = {}

    class << self
      # Called from every `deconstruct_keys` implementation after the result
      # hash is assembled.  Uses Prism to locate the hash pattern at the
      # call site, extracts symbol promotion targets, promotes values to their
      # destinations, and replaces each promoted entry in `result` with the
      # target symbol so that Ruby's `===` comparison in the pattern succeeds.
      #
      # Symbol target conventions (used as the value in the hash pattern):
      #
      #   { KEY: :_ }          promotes value as constant KEY  (KEY must start with uppercase)
      #   { KEY: :ConstName }  promotes value as constant ConstName
      #   { KEY: :'Ns::Name' } promotes value as Ns::Name (namespaced constant)
      #   { KEY: :'$global' }  sets global variable $global
      #   { KEY: :'@ivar' }    sets instance variable @ivar on the call-site object
      #   { KEY: :'@@cvar' }   sets class variable @@cvar in the call-site context
      #
      # Any symbol not matching the above patterns is left untouched so normal
      # pattern matching equality checks against actual exported values work.
      def auto_promote(result, caller_locs)
        caller_loc =
          caller_locs.find do |l|
            p = l.absolute_path
            p && p != THIS_FILE && File.exist?(p)
          end
        return unless caller_loc

        path = caller_loc.absolute_path
        lineno = caller_loc.lineno

        deferred = [] # [{name:, value:}] for ivars/cvars that need a binding

        find_symbol_targets(path, lineno).each do |key_str, sym_str|
          key = key_str.to_sym
          next unless result.key?(key)

          value = result[key]

          case sym_str
          when '_'
            promote_const(key_str, value)
            result[key] = :_
          when /\A[A-Z]/
            promote_const(sym_str, value)
            result[key] = sym_str.to_sym
          when /\A\$/
            promote_global(sym_str, value)
            result[key] = sym_str.to_sym
          when /\A@/
            deferred << { name: sym_str, value: value }
            result[key] = sym_str.to_sym

            # Lowercase/other symbols are not promotion targets -- left untouched
            # so literal symbol matching (e.g. { status: :active }) keeps working.
          end
        end

        schedule_binding_promotions(deferred, path) unless deferred.empty?
      rescue StandardError
        # Best-effort -- never interfere with normal pattern matching
      end

      private

      # Parses the file with Prism (cached) and walks the AST to find every
      # HashPatternNode that spans `lineno`, returning [[key_str, sym_str], ...]
      # for AssocNode entries whose value is a SymbolNode.
      def find_symbol_targets(path, lineno)
        return [] unless defined?(Prism)

        ast =
          @ast_cache[path] ||= (
            begin
              Prism.parse_file(path)
            rescue StandardError
              nil
            end
          )
        return [] unless ast&.success?

        targets = []
        collect_hash_pattern_symbols(ast.value, lineno, targets)
        targets
      end

      # Recursively walks `node`, collecting promotion pairs from any
      # HashPatternNode whose source range includes `lineno`.
      def collect_hash_pattern_symbols(node, lineno, targets)
        return unless node

        if node.is_a?(Prism::HashPatternNode)
          loc = node.location
          if lineno >= loc.start_line && lineno <= loc.end_line
            node.elements.each do |elem|
              next unless elem.is_a?(Prism::AssocNode)
              next unless elem.value.is_a?(Prism::SymbolNode)
              next unless elem.key.is_a?(Prism::SymbolNode)

              targets << [elem.key.unescaped, elem.value.unescaped]
            end
          end
        end

        node.child_nodes.each do |child|
          collect_hash_pattern_symbols(child, lineno, targets) if child
        end
      end

      # Promotes `value` to the constant path `const_path` (e.g. "Foo" or
      # "Foo::Bar").  Intermediate modules are created if absent.
      def promote_const(const_path, value)
        parts = const_path.split('::')
        mod = Object
        parts[..-2].each do |part|
          mod =
            (
              if mod.const_defined?(part, false)
                mod.const_get(part, false)
              else
                mod.const_set(part, Module.new)
              end
            )
        end
        unless mod.const_defined?(parts.last, false)
          mod.const_set(parts.last, value)
        end
      rescue NameError
        # Invalid constant name (e.g. key was lowercase) -- ignore
      end

      # Sets a global variable by injecting the value through a local binding
      # (no thread locals required -- globals are process-wide regardless of
      # which binding the eval runs in).
      def promote_global(name, value)
        b = binding
        b.local_variable_set(:__rb_pkg_v, value)
        b.eval("#{name} = __rb_pkg_v")
      end

      # Registers a one-shot TracePoint that fires on the next line in `path`
      # and sets instance / class variables in the caller's binding context.
      # Values are captured in the closure -- no thread locals needed.
      def schedule_binding_promotions(promotions, path)
        tp =
          TracePoint.new(:line) do |t|
            unless (
                     begin
                       File.realpath(t.path)
                     rescue StandardError
                       t.path
                     end
                   ) == path
              next
            end

            b = t.binding
            promotions.each do |promo|
              b.local_variable_set(:__rb_pkg_v, promo[:value])
              b.eval("#{promo[:name]} = __rb_pkg_v")
            rescue NameError
              # Invalid variable name in this context -- ignore
            end
            tp.disable
          end
        tp.enable
      rescue StandardError
        # TracePoint may be unavailable in some contexts (e.g. inside Ruby::Box)
      end
    end
  end
end

# Inject the module into Kernel
Kernel.prepend(Rb::Package)
