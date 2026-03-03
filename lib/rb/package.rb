raise 'Ruby 4.0+ is required for Rb::Package' if RUBY_VERSION.to_f < 4.0

module Rb
  module Package
    def import(path)
      box = Ruby::Box.new
      box.require(__FILE__)
      box.require(File.expand_path(path, Dir.pwd))

      exports = box.const_get(:EXPORTS)
      process_exports(exports)
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

    def process_exports(exports)
      if exports.is_a?(Hash)
        Module.new do
          const_set(:EXPORTS, exports)
          private_constant :EXPORTS

          exports.each do |k, v|
            if k.to_s.match?(/^[A-Z]/)
              # Capitalized keys become Constants
              const_set(k, v)
            else
              # Lowercase keys become Singleton Methods
              define_singleton_method(k) do |*args, **kw, &blk|
                v.respond_to?(:call) ? v.call(*args, **kw, &blk) : v
              end
            end
          end

          # Implement `#deconstruct_keys` to enable Ruby Pattern Matching
          def self.deconstruct_keys(keys)
            module_exports = const_get(:EXPORTS)
            keys ? module_exports.slice(*keys) : module_exports
          end
        end
      else
        # Single export just returns the object directly
        exports
      end
    end
  end
end

# Inject the module into Kernel
Kernel.prepend(Rb::Package)
