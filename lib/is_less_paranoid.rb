require 'activerecord'

module IsLessParanoid
  # Call this in your model to enable all the safety-net goodness
  #
  # Example:
  #
  # class Android < ActiveRecord::Base
  #   is_less_paranoid
  # end
  #

  def is_less_paranoid opts = {}
    opts[:field] ||= [:deleted_at, Proc.new{Time.now.utc}, nil]
    class_inheritable_accessor :destroyed_field, :field_destroyed, :field_not_destroyed
    self.destroyed_field, self.field_destroyed, self.field_not_destroyed = opts[:field]

    extend ClassMethods
    include InstanceMethods
    
    # :clone => :with_destroyed # :clone => :alive # :clone => false
    default_options = {:suffix => opts[:prefix] ? nil : ((opts[:clone] == :with_destroyed) ? 'WithDestroyed' : 'Alive'), :clone => :alive}
    clone_class_and_apply_constraints(opts.reverse_merge(default_options))
  end

  module CloneClassMethods
    def paranoid_original_class
      @paranoid_original_class
    end
  
    def sti_name
      @paranoid_original_class.sti_name
    end
  
    def descends_from_active_record?
      @paranoid_original_class.descends_from_active_record?
    end
  end

  module ClassMethods
    def inherited(subclass) # :nodoc:
      super
      subclass.clone_class_and_apply_constraints(@paranoid_options) unless @cloning || (@paranoid_original_class !=self)
    end
  
    def clone_class_and_apply_constraints(options) # :nodoc:
      @paranoid_options = options
      @paranoid_options[:scope_destroyed] = case options[:clone]
        when :with_destroyed then true
        when :alive then false
        when false then true
        else
          raise ArgumentError, "Unknown value #{options[:clone]} for option :clone"
      end
      
      if options[:clone]
        table_name  # force naming the table (works even if set_table_name has been called)

        # Create a cloned class in the same namespace with the supplied prefix and suffix
        nesting = self.name.split("::")
        original_class_name = nesting.pop
        clone_class_name = "#{options[:prefix]}#{original_class_name}#{options[:suffix]}"
        namespace = "::#{nesting.join("::")}".constantize
        @cloning = true # FIXME: Not thread safe, should use a Mutex
        namespace.module_eval "class #{clone_class_name} < #{original_class_name}; end"
        @cloning = false
        clone_class = namespace.const_get(clone_class_name)
        
        @paranoid_original_class = self
        clone_class.instance_variable_set(:@paranoid_original_class, self)
        clone_class.instance_variable_set(:@paranoid_options, @paranoid_options.reverse_merge(:scope_destroyed => (options[:clone] == :alive)))

        clone_class.extend CloneClassMethods
      end
      
      klass = (options[:clone] == :alive) ? clone_class : self
      
      # This is the real magic. All calls made to this model will append
      # the conditions deleted_at => nil (or whatever your destroyed_field
      # and field_not_destroyed are). All exceptions require using
      # exclusive_scope (see self.delete_all, self.count_with_destroyed,
      # and self.find_with_destroyed defined in the module ClassMethods)
      klass.send(:default_scope, :conditions => {destroyed_field => field_not_destroyed})
    end
    protected :inherited, :clone_class_and_apply_constraints
    
    def paranoid_original_class
      self
    end
  
    # Actually delete the model, bypassing the safety net. Because
    # this method is called internally by Model.delete(id) and on the
    # delete method in each instance, we don't need to specify those
    # methods separately
    def delete_all conditions = nil
      self.with_exclusive_scope { super conditions }
    end

    # Use update_all with an exclusive scope to restore undo the soft-delete.
    # This bypasses update-related callbacks.
    #
    # By default, restores cascade through associations that are belongs_to
    # :dependent => :destroy and under is_paranoid. You can prevent restoration
    # of associated models by passing :include_destroyed_dependents => false,
    # for example:
    #
    #   Android.restore(:include_destroyed_dependents => false)
    #
    # Alternatively you can specify which relationships to restore via :include,
    # for example:
    #
    #  Android.restore(:include => [:parts, memories])
    #
    # Please note that specifying :include means you're not using
    # :include_destroyed_dependents by default, though you can explicitly use
    # both if you want all has_* relationships and specific belongs_to
    # relationships, for example
    #
    #  Android.restore(:include => [:home, :planet], :include_destroyed_dependents => true)
    def restore(id, options = {})
      options.reverse_merge!({:include_destroyed_dependents => true}) unless options[:include]
      with_exclusive_scope do
        update_all(
        "#{destroyed_field} = #{connection.quote(field_not_destroyed)}",
        "id = #{id}"
        )
      end

      self.reflect_on_all_associations.each do |association|
        if association.options[:dependent] == :destroy and association.klass.respond_to?(:restore)
          dependent_relationship = association.macro.to_s =~ /^has/
          if should_restore?(association.name, dependent_relationship, options)
            if dependent_relationship
              restore_related(association.klass, association.primary_key_name, id, options)
            else
              restore_related(
                association.klass,
                association.klass.primary_key,
                self.first(id).send(association.primary_key_name),
                options
              )
            end
          end
        end
      end
    end

    # find_with_destroyed and other blah_with_destroyed and
    # blah_destroyed_only methods are defined here
    def method_missing name, *args, &block
      if name.to_s =~ /^(.*)(_destroyed_only|_with_destroyed)$/ and self.respond_to?($1)
        self.extend(Module.new{
          if $2 == '_with_destroyed'
            # Example:
            # def count_with_destroyed(*args)
            #   self.with_exclusive_scope{ self.send(:count, *args) }
            # end
            define_method name do |*args|
              self.with_exclusive_scope{ self.send($1, *args) }
            end
          else

            # Example:
            # def count_destroyed_only(*args)
            #   self.with_exclusive_scope do
            #     with_scope({:find => { :conditions => ["#{destroyed_field} IS NOT ?", nil] }}) do
            #       self.send(:count, *args)
            #     end
            #   end
            # end
            define_method name do |*args|
              self.with_exclusive_scope do
                with_scope({:find => { :conditions => ["#{self.table_name}.#{destroyed_field} IS NOT ?", field_not_destroyed] }}) do
                  self.send($1, *args, &block)
                end
              end
            end

          end
        })
      self.send(name, *args, &block)
      else
        super(name, *args, &block)
      end
    end

    # with_exclusive_scope is used internally by ActiveRecord when preloading
    # associations.  Unfortunately this is problematic for is_paranoid since we
    # want preloaded is_paranoid items to still be scoped to their deleted conditions.
    # so we override that here.
    def with_exclusive_scope(method_scoping = {}, &block)
      # this is rather hacky, suggestions for improvements appreciated... the idea
      # is that when the caller includes the method preload_associations, we want
      # to apply our is_paranoid conditions
      if @paranoid_options[:scope_destroyed]
        if caller.any?{|c| c =~ /\d+:in `preload_associations'$/}
          method_scoping.deep_merge!(:find => {:conditions => {destroyed_field => field_not_destroyed} })
        end
      end
      super method_scoping, &block
    end

    protected

    def should_restore?(association_name, dependent_relationship, options) #:nodoc:
      ([*options[:include]] || []).include?(association_name) or
        (options[:include_destroyed_dependents] and dependent_relationship)
    end

    def restore_related klass, key_name, id, options #:nodoc:
      klass.find_destroyed_only(:all,
        :conditions => ["#{key_name} = ?", id]
      ).each do |model|
        model.restore(options)
      end
    end
  end

  module InstanceMethods
    def self.included(base)
      base.class_eval do
        unless method_defined? :method_missing
          def method_missing(meth, *args, &block); super; end
        end
        alias_method :old_method_missing, :method_missing
        alias_method :method_missing, :is_paranoid_method_missing
      end
    end

    def is_paranoid_method_missing name, *args, &block
      # if we're trying for a _____with_destroyed method
      # and we can respond to the _____ method
      # and we have an association by the name of _____
      if name.to_s =~ /^(.*)(_with_destroyed)$/ and
          self.respond_to?($1) and
          (assoc = self.class.reflect_on_all_associations.detect{|a| a.name.to_s == $1})

        parent_klass = Object.module_eval("::#{assoc.class_name}", __FILE__, __LINE__)

        self.class.send(
          :include,
          Module.new{                                 # Example:
            define_method name do |*args|             # def android_with_destroyed
              parent_klass.first_with_destroyed(      #   Android.first_with_destroyed(
                :conditions => {                      #     :conditions => {
                  parent_klass.primary_key =>         #       :id =>
                    self.send(assoc.primary_key_name) #         self.send(:android_id)
                }                                     #     }
              )                                       #   )
            end                                       # end
          }
        )
        self.send(name, *args, &block)
      else
        old_method_missing(name, *args, &block)
      end
    end

    # Mark the model deleted_at as now.
    def destroy_without_callbacks
      self.class.update_all(
        "#{destroyed_field} = #{self.class.connection.quote(( field_destroyed.respond_to?(:call) ? field_destroyed.call : field_destroyed))}",
        "id = #{self.id}"
      )
      self
    end

    # Override the default destroy to allow us to flag deleted_at.
    # This preserves the before_destroy and after_destroy callbacks.
    # Because this is also called internally by Model.destroy_all and
    # the Model.destroy(id), we don't need to specify those methods
    # separately.
    def destroy
      return false if callback(:before_destroy) == false
      result = destroy_without_callbacks
      callback(:after_destroy)
      self
    end

    # Set deleted_at flag on a model to field_not_destroyed, effectively
    # undoing the soft-deletion.
    def restore(options = {})
      self.class.restore(id, options)
      self
    end

    # Checks whenever this record is destroyed
    # (so that returned records from find with destroyed may be checked against their state)
    def destroyed?
      send(self.class.destroyed_field) != self.class.field_not_destroyed
    end

    # Records of the original class and the clone class must match
    def ==(comparison_object)
      super ||
        ((self.class.paranoid_original_class == (comparison_object.class.paranoid_original_class rescue nil)) &&
          comparison_object.id == id &&
          !comparison_object.new_record?)
    end
  end

end

ActiveRecord::Base.send(:extend, IsLessParanoid)
