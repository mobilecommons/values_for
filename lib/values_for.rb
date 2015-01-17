module ValuesFor

  def self.included(base)
    base.extend(SingletonMethods)
  end

  module SingletonMethods

    # Creates an enumerable attribute on an ActiveRecord model.  Usage is as
    # follows:
    #
    #   values_for :state, :has => [ :new, :composed, :served, :eaten ]
    #
    # Any additional options will be passed directly to the ActiveRecord method
    # :validates_inclusion_of, which is used to validate the assigned values to
    # this attribute.  Requires a column of type VARCHAR with the name of the
    # first argument to +values_for+.
    def values_for(*args)
      opts        = args.extract_options!
      attribute   = args.first

      attribute_s = attribute.to_s

      additives         = Array.wrap(opts[:add])
      plural_attribute  = attribute_s.pluralize

      prefix = opts.has_key?(:prefix) ? opts[:prefix] : attribute_s

      # We don't accept the case where an empty string is a valid value, but we should provide a useful error message
      raise ArgumentError, "Can't use values_for with an empty string" if opts[:has].any?{|v| v.respond_to?(:empty?) && v.empty? }

      # Valid values can be symbols or strings, but let's convert them all to strings
      valid_strings = opts[:has].map{|v| v.to_s }

      valid_strings.each do |val_s|
        prefixed_val = [ prefix, val_s ].compact.join('_')
        prefixed_val = parameterize_without_downcase(prefixed_val,'_')

        # Create +optional+ constants
        if additives.include?(:constants)
          constant_name = prefixed_val.upcase
          const_already_defined = (RUBY_VERSION < '1.9') ? const_defined?(constant_name) : const_defined?(constant_name, false)
          if const_already_defined
            LOG.warn "values_for: Can not create constant #{constant_name} because it's already defined" if defined?(LOG) && LOG.respond_to?(:warn)
          else
            const_set(constant_name, val_s)
          end
        end


        # Create +optional+ named scopes, Rails <= 2.3.x
        named_scope prefixed_val, :conditions => { attribute => val_s } if additives.include?(:named_scopes)
        
        # Create +optional+ scopes, Rails >= 3.0.x
        scope prefixed_val, where(attribute => val_s) if additives.include?(:scopes)

        # Create +optional+ predicate methods, but don't overwrite existing methods
        if additives.include?(:predicate_methods)
          predicate_val = "#{prefixed_val}?"
          if (instance_methods + private_instance_methods).include?(predicate_val)
            LOG.warn "values_for: Can not create predicate method #{predicate_val} because #{self} already responds to it" if defined?(LOG) && LOG.respond_to?(:warn)
          else
            define_method(predicate_val) do    # def foo?
              read_attribute(attribute) == val_s    #   read_attribute(:foo) == 'foo'
            end                                     # end
          end
        end
      end

      # Accepts assignment both from String and Symbol form of valid values.
      validation_options = {:message => "%{value} is not included in the list"}
      validation_options.merge!(opts.except(:has, :prefix, :add))
      validation_options.merge!(:in => valid_strings | valid_strings.map{|s| s.to_sym })

      validates_inclusion_of attribute, validation_options

      define_method(attribute_s) do                             # def foo
        unless self[attribute].nil? || self[attribute].empty?   #   unless self[:foo].nil? || self[:foo].empty?
          self[attribute].to_s                                  #     self[:foo].to_s
        end                                                     #   end
      end                                                       # end

      # Custom setter method casting all attribute input to String, allows
      # assignment from Symbol form.
      define_method(attribute_s + '=') do |other|         # def foo=(other)
        self[attribute] = other.nil? ? nil : other.to_s   #   self[foo] = other unless other.nil?
      end                                                 # end

      # Make collection of all valid attribute Symbols available to user
      # from plural name of attribute as class method.
      cattr_reader plural_attribute.to_sym
      class_variable_set(:"@@#{plural_attribute}", opts[:has])
    end


    def parameterize_without_downcase(string, sep = '-')
      parameterized_string = string.dup
      # Turn unwanted chars into the seperator
      parameterized_string.gsub!(/[^a-z0-9\-_]+/i, sep)
      unless sep.blank?
        re_sep = Regexp.escape(sep)
        # No more than one of the separator in a row.
        parameterized_string.gsub!(/#{re_sep}{2,}/, sep)
        # Remove leading/trailing separator.
        parameterized_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')
      end
      parameterized_string
    end
  end

end

ActiveRecord::Base.send(:include, ValuesFor)
