# frozen_string_literal: true

module Symbiont
  # A trigger that considers only public methods of executable contexts
  # during method dispatching.
  #
  # @see Symbiont::Trigger
  #
  # @api private
  # @since 0.1.0
  class PublicTrigger < Trigger
    # Returns the first context that is able to respond to the required method.
    # The context is chosen in the context direction order (see #__context_direction__).
    # Raises NoMethodError excepition when no one of the contexts are able to respond to
    # the required method.
    # Basicaly (in #super), abstract implementation raises NoMethodError.
    #
    # @param method_name [String,Symbol] Method that a context should respond to.
    # @raise NoMethodError
    #   Is raised when no one of the contexts are able to respond to the required method.
    # @return [Objcet]
    #
    # @see Symbiont::Trigger#__actual_context__
    #
    # @api private
    # @since 0.1.0
    def __actual_context__(method_name)
      __directed_contexts__.find do |context|
        begin
          context.respond_to?(method_name, false)
        rescue ::NoMethodError
          # NOTE:
          #   this situation is caused when context object does not support
          #   #resond_to? method (for example, BasicObject instances does not support this method)

          context_singleton = __extract_singleton_object__(context)

          context_singleton.public_methods(false).include?(method_name) ||
          context_singleton.superclass.public_instance_methods(false).include?(method_name)
        end
      end || super
    end

    # Returns a corresponding public method object of the actual context.
    #
    # @param method_name [String,Symbol] Method name
    # @return [Method]
    #
    # @see [Symbiont::Trigger#method]s
    #
    # @api private
    # @since 0.5.0
    def method(method_name)
      __context__ = __actual_context__(method_name)

      begin # NOTE: block is used cuz #__actual_context__ can raise NoMethodError too.
        __context__.method(method_name)
      rescue ::NoMethodError
        # NOTE:
        #   this situation is caused when the context object does not respond
        #   to #method method (BasicObject instances for example). We can extract
        #   method objects via it's singleton class.

        __context_singleton__ = __extract_singleton_object__(__context__)
        __context_singleton__.superclass.public_instance_method(method_name).bind(__context__)
      end
    end
  end
end
