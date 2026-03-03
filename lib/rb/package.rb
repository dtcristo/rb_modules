raise 'Ruby 4.0+ is required for Rb::Package' if RUBY_VERSION.to_f < 4.0

module Rb
  module Package
    def self.gem_require_paths(name, visited = Set.new)
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

    module Kernel
      def import(path)
        box = Ruby::Box.new
        box.require(__FILE__)

        # Resolve relative/absolute file paths; fall back to gem name lookup
        expanded = File.expand_path(path, Dir.pwd)
        if File.exist?(expanded) || File.exist?("#{expanded}.rb")
          box.require(expanded)
        else
          # Gem import: inject transitive load paths into the box first
          Rb::Package
            .gem_require_paths(path)
            .each { |p| box.eval("$LOAD_PATH << #{p.inspect}") }
          box.require(path)
        end

        # Check for Exports module - hash exports
        begin
          return box::Rb::Package::Exports
        rescue NameError
          # Fall back to EXPORT constant - single exports
          begin
            return box::Rb::Package::EXPORT
          rescue NameError
            # Bare package/gem with no exports — return the Box instance directly
            # Inject deconstruct_keys for pattern matching support
            box.define_singleton_method(:deconstruct_keys) do |keys|
              return {} unless keys

              keys.each_with_object({}) do |key, hash|
                name = key.to_s
                hash[key] = if name.match?(/\A[A-Z]/)
                  begin
                    const_get(name)
                  rescue NameError
                    next
                  end
                else
                  begin
                    eval(name)
                  rescue NameError, NoMethodError
                    next
                  end
                end
              end
            end
            return box
          end
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

        if value.is_a?(Hash)
          # Create Exports module for hash exports
          exports_module = Module.new

          value.each do |k, v|
            if k.to_s.match?(/^[A-Z]/)
              exports_module.const_set(k, v)
            else
              exports_module.define_singleton_method(k) do |*args, **kw, &blk|
                v.respond_to?(:call) ? v.call(*args, **kw, &blk) : v
              end
            end
          end

          # Attach deconstruct_keys to the Exports module
          exports_module.define_singleton_method(:deconstruct_keys) do |keys|
            keys ? value.slice(*keys) : value
          end

          Rb::Package.const_set(:Exports, exports_module)
        else
          # Single exports
          Rb::Package.const_set(:EXPORT, value)
        end
      end
    end
  end
end

# Inject only the Kernel module into Kernel
Kernel.prepend(Rb::Package::Kernel)
