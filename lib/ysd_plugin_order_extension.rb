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
        {:name => 'order.request_reservations'},
        {:value => 'true',
         :description => 'Allow the customers to request reservation (without payment)'})


      SystemConfiguration::Variable.first_or_create(
        {:name => 'order.payment'},
        {:value => 'false',
         :description => 'Integrate the payment in the booking process. Values: true, false',
         :module => :booking})

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

      SystemConfiguration::Variable.first_or_create(
        {:name => 'order.payment_cadence'},
        {:value => '48',
         :description => 'Cadence in hours from the reservation date to today',
         :module => :booking})

      SystemConfiguration::Variable.first_or_create(
        {:name => 'order.item_hold_time'},
        {:value => '72',
         :description => 'Reservation expiration time',
         :module => :booking})

      ContentManagerSystem::Template.first_or_create({:name => 'order_manager_notification'},
          {:description=>'Mensaje que se envía al gestor de reservas al recibir un nuevo pedido',
           :text => ::Yito::Model::Order::Order.manager_notification_template})

      ContentManagerSystem::Template.first_or_create({:name => 'order_manager_notification_pay_now'},
          {:description => 'Mensaje que se envía al gestor de reservas cuando un cliente realiza un pedido con pago',
           :text => ::Yito::Model::Order::Order.manager_notification_pay_now_template})

      ContentManagerSystem::Template.first_or_create({:name => 'order_confirmation_manager_notification'},
          {:description => 'Mensaje que se envía al gestor de reservas cuando se confirma un pedido',
           :text => ::Yito::Model::Order::Order.manager_confirm_notification_template})

      ContentManagerSystem::Template.first_or_create({:name => 'order_customer_req_notification'},
          {:description=>'Mensaje que se envía al cliente cuando realiza un pedido (sin pago)',
           :text => ::Yito::Model::Order::Order.customer_notification_booking_request_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'order_customer_req_pay_now_notification'},
          {:description=>'Mensaje que se envía al cliente cuando realiza un pedido (con pago)',
           :text => ::Yito::Model::Order::Order.customer_notification_request_pay_now_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'order_customer_notification'},
          {:description=>'Mensaje que se envía al cliente cuando se confirma el pedido',
           :text => ::Yito::Model::Order::Order.customer_notification_booking_confirmed_template}) 

      ContentManagerSystem::Template.first_or_create({:name => 'order_customer_notification_payment_enabled'},
          {:description=>'Mensaje que se envía al cliente cuando se habilita el pago del pedido',
           :text => ::Yito::Model::Order::Order.customer_notification_payment_enabled_template}) 

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

    # ======== Aspects ==================

    #
    # Retrieve an array of the aspects defined in the plugin
    #
    # The attachment aspect (complement)
    #
    def aspects(context={})
      
      app = context[:app]
      
      aspects = []
      aspects << ::Plugins::Aspect.new(:request_information, app.t.aspect.request_information,
        Aspect::RequestInformation, RequestInformationAspectDelegate.new)
                                               
      return aspects
       
    end     
    
    #
    # ---------- Path prefixes to be ignored ----------
    #

    #
    # Ignore the following path prefixes in language processor
    #
    def ignore_path_prefix_language(context={})
      %w(/p/order/payment-gateway /p/order/pay /p/myorder /p/activity)
    end

    #
    # Ignore the following path prefix in cms
    #
    def ignore_path_prefix_cms(context={})
      %w(/p/order/payment-gateway /p/order/pay /p/myorder /p/activity)
    end

    #
    # Ignore the following path prefix in breadcrumb
    #
    def ignore_path_prefix_breadcrumb(context={})
      %w(/p/order/payment-gateway /p/order/pay /p/myorder /p/activity)
    end    

  end
end