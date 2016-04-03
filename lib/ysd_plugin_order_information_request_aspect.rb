require 'ui/ysd_ui_fieldset_render' unless defined?UI::FieldSetRender

module Huasi
  #
  # Request information aspect
  #
  class RequestInformationAspectDelegate
    include ContentManagerSystem::Support
    
    #
    # Custom representation (the attachments)
    #
    # @param [Hash] the context
    # @param [Object] the element
    #
    def custom(context={}, element, aspect_model)
    
      app = context[:app]
      
      renderer = ::UI::FieldSetRender.new('requestinformation', app)
      renderer.render('view','',{:element => element, :show_title => false})

    end      
    
    #
    # Custom representation (the comment) 
    #
    # @param [Hash] context
    # @param [Object] object
    #
    def custom_extension(context={}, element, aspect_model)

      app = context[:app]
    
      renderer = ::UI::FieldSetRender.new('requestinformation', app)
      renderer.render('viewextension','',{:element => element})
    
    end       
      
  end
end