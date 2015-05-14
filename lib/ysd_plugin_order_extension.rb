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

      SystemConfiguration::Variable.first_or_create(
        {:name => 'order.deposit'},
        {:value => '40',
         :description => 'Deposit percentage or 0 if no deposit management',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'order.allow_deposit_payment'},
        {:value => 'true',
         :description => 'Allow total payment. Values: true, false',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'order.allow_total_payment'},
        {:value => 'true',
         :description => 'Allow total payment. Values: true, false',
         :module => :booking})

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
    
    #
    # ---------- Path prefixes to be ignored ----------
    #

    #
    # Ignore the following path prefixes in language processor
    #
    def ignore_path_prefix_language(context={})
      %w(/p/order/payment-gateway /p/order/pay /p/myorder)
    end

    #
    # Ignore the following path prefix in cms
    #
    def ignore_path_prefix_cms(context={})
      %w(/p/order/payment-gateway /p/order/pay /p/myorder)
    end

  end
end