require 'ysd-plugins_viewlistener' unless defined?Plugins::ViewListener

#
# Huasi Order Extension
#
module Huasi
  class OrderExtension < Plugins::ViewListener

    # ========= Installation =================

    # 
    # Install the plugin
    #
    def install(context={})

    end
    

    # --------- Menus --------------------
    
    #
    # It defines the admin menu menu items
    #
    # @return [Array]
    #  Menu definition
    #
    def menu(context={})
      
      app = context[:app]

      menu_items = [                    
                    ]                      
    
    end  

    # ========= Routes ===================
            
    # routes
    #
    # Define the module routes, that is the url that allow to access the funcionality defined in the module
    #
    #
    def routes(context={})
    
      routes = [                                             
               ]
        
    end
    
  end
end