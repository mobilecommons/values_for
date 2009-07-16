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
        
        # Create +optional+ constants
        const_set(prefixed_val.upcase, val_s) if additives.include?(:constants)
        
        # Create +optional+ named scopes
        named_scope prefixed_val, :conditions => { attribute => val_s } if additives.include?(:named_scopes)

        # Create +optional+ predicate methods, but don't overwrite existing methods
        if additives.include?(:predicate_methods) && !self.instance_methods.include?(prefixed_val)
          define_method(prefixed_val + '?') do    # def foo?
            read_attribute(attribute) == val_s    #   read_attribute(:foo) == 'foo'  
          end                                     # end
        end
      end
      
      # Accepts assignment both from String and Symbol form of valid values.
      validates_inclusion_of attribute, opts.except(:has, :prefix, :add).
        merge(:in => valid_strings | valid_strings.map{|s| s.to_sym } )
      
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
  end
  
end

ActiveRecord::Base.send(:include, ValuesFor)