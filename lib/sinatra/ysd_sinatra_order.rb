module Sinatra
  module YitoExtension
    module OrderHelper
      def load_order
        conf_allow_total_payment = SystemConfiguration::Variable.get_value('order.allow_total_payment','false').to_bool
        conf_allow_deposit_payment = SystemConfiguration::Variable.get_value('order.allow_deposit_payment','false').to_bool
        @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
        locals = {:order => @order,
                  :order_allow_total_payment => conf_allow_total_payment,
                  :order_allow_deposit_payment => conf_allow_deposit_payment}
        load_page :order, :locals => locals
      end
    end
    module Order
      def self.registered(app)

        app.settings.views = Array(app.settings.views).push(
          File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 
          'views')))
        app.settings.translations = Array(app.settings.translations).push(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'i18n')))      

        app.set :ordercharge_gateway_return_ok, '/p/order/payment-gateway-return/ok'
        app.set :ordercharge_gateway_return_cancel, '/p/order/payment-gateway-return/cancel'
        app.set :ordercharge_gateway_return_nok, '/p/order/payment-gateway-return/nok'


        #
        # Shows an order: To be managed by the customer
        #   
        app.route :get, :post, ['/p/myorder/:id/?*'] do
          if @order = ::Yito::Model::Order::Order.get_by_free_access_id(params[:id])
            if request.post?
              @order.transaction do

                if @order.request_customer_address
                  customer_address = @order.customer_address || LocationDataSystem::Address.new
                  customer_address.street = params[:street]
                  customer_address.number = params[:number]
                  customer_address.complement = params[:complement]
                  customer_address.city = params[:city]
                  customer_address.state = params[:state]
                  customer_address.country = params[:country]
                  customer_address.zip = params[:zip]
                  customer_address.save
                  if @order.customer_address.nil?
                    @order.customer_address = customer_address
                    @order.save
                  end
                end

                # Update customers data
                if params[:order_item_customers]
                  params[:order_item_customers].each do |item|
                    if order_item_customer = ::Yito::Model::Order::OrderItemCustomer.get(item[:id])
                      order_item_customer.customer_name = item[:customer_name] if item.has_key?('customer_name')
                      order_item_customer.customer_surname = item[:customer_surname] if item.has_key?('customer_surname')
                      order_item_customer.customer_document_id = item[:customer_document_id] if item.has_key?('customer_document_id')
                      order_item_customer.customer_phone = item[:customer_phone] if item.has_key?('customer_phone')
                      order_item_customer.customer_email = item[:customer_email] if item.has_key?('customer_email')
                      order_item_customer.customer_height = item[:customer_height] if item.has_key?('customer_height')
                      order_item_customer.customer_weight = item[:customer_weight] if item.has_key?('customer_weight')
                      order_item_customer.customer_allergies_or_intolerances = item[:customer_allergies_or_intolerances] if item.has_key?('customer_allergies_or_intolerances')
                      order_item_customer.save
                    end
                    @order.reload
                  end
                  #flash[:notice] = 'Datos actualizados'
                end
              end
            end
            load_order
          else
            status 404
          end
        end

        #
        # Register a payment on the order
        #
        app.post '/p/order/pay/?*', 
          :allowed_origin => lambda { SystemConfiguration::Variable.get_value('site.domain') } do
          
          if order = order = ::Yito::Model::Order::Order.get(params[:id].to_i)
            payment = params[:payment]
            payment_method = params[:payment_method_id]
            if charge = order.create_online_charge!(payment, payment_method)
              session[:order_id] = order.id
              session[:charge_id] = charge.id
              status, header, body = call! env.merge("PATH_INFO" => "/charge", 
                "REQUEST_METHOD" => 'GET')
            else
              redirect "/p/myorder/#{order.free_access_id}"
            end            
          else
            status 404
          end 

        end

        #
        # It returns from the payment gateway when the payment has been done
        # 
        # Notifies to the user that the reservation has finished
        #   
        app.get '/p/order/payment-gateway-return/ok' do

          if session[:charge_id]
            order = ::Yito::Model::Order::OrderCharge.order_from_charge(session[:charge_id])
            conf_allow_total_payment = SystemConfiguration::Variable.get_value('order.allow_total_payment','false').to_bool
            conf_allow_deposit_payment = SystemConfiguration::Variable.get_value('order.allow_deposit_payment','false').to_bool
            locals = {:order => order, 
                      :order_allow_total_payment => conf_allow_total_payment,
                      :order_allow_deposit_payment => conf_allow_deposit_payment}
            load_page(:order_finished, :locals => locals)
          else
            logger.error "Back from payment gateway NOT charge in session"
            status 404
          end
        end

        #
        # It returns from the payment gateway when the user returns or cancel
        #
        # Shows the reservation information
        #
        app.get '/p/order/payment-gateway-return/cancel' do

          if session[:charge_id]
             order = ::Yito::Model::Order::OrderCharge.order_from_charge(session[:charge_id])
             conf_allow_total_payment = SystemConfiguration::Variable.get_value('order.allow_total_payment','false').to_bool
             conf_allow_deposit_payment = SystemConfiguration::Variable.get_value('order.allow_deposit_payment','false').to_bool
             locals = {:order => order, 
                      :order_allow_total_payment => conf_allow_total_payment,
                      :order_allow_deposit_payment => conf_allow_deposit_payment}
             load_page :order, :locals => locals
          else
             logger.error "Back from payment gateway NOT charge in session"
             status 404
          end
        end

        #
        # It returns from the payment gateway when the payment has been denied
        #
        # Shows the reservation payment denied
        #
        app.get '/p/order/payment-gateway-return/nok' do
          if session[:charge_id]
            order = ::Yito::Model::Order::OrderCharge.order_from_charge(session[:charge_id])
            locals = {}
            conf_allow_total_payment = SystemConfiguration::Variable.get_value('order.allow_total_payment','false').to_bool
            conf_allow_deposit_payment = SystemConfiguration::Variable.get_value('order.allow_deposit_payment','false').to_bool
            locals = {:order => order, 
                      :order_allow_total_payment => conf_allow_total_payment,
                      :order_allow_deposit_payment => conf_allow_deposit_payment}
            load_page(:order_denied, :locals => locals)
          else
            logger.error "Back from payment gateway NOT charge in session"
            status 404
          end
        end                

      end
    end
  end
end