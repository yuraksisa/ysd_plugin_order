#require 'ysd_md_calendar' unless defined?Yito::Model::Calendar::Calendar

module Sinatra
  module YitoExtension
    module OrderManagementRESTApi

      def self.registered(app)

        #                    
        # Query orders
        #
        ["/api/orders","/api/orders/page/:page"].each do |path|
          
          app.post path, :allowed_usergroups => ['order_manager', 'booking_manager', 'staff']  do

            page = [params[:page].to_i, 1].max  
            page_size = 20
            offset_order_query = {:offset => (page - 1)  * page_size, :limit => page_size, :order => [:creation_date.desc]} 
          
            if request.media_type == "application/x-www-form-urlencoded"
              search_text = if params[:search]
                              params[:search]
                            else
                              request.body.rewind
                              request.body.read
                            end
              total, data = ::Yito::Model::Order::Order.text_search(search_text,offset_order_query)
            else
              data, total = ::Yito::Model::Order::Order.all_and_count(offset_order_query)
            end

            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get orders
        #
        app.get "/api/orders", :allowed_usergroups => ['order_manager', 'booking_manager', 'staff']  do

          data = ::Yito::Model::Order::Order.all

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get an order
        #
        app.get "/api/order/:id", :allowed_usergroups => ['order_manager','booking_manager','staff']  do
        
          data = ::Yito::Model::Order::Order.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a new order
        #
        app.post "/api/order", :allowed_usergroups => ['order_manager','booking_manager','staff']  do
        
          data_request = body_as_json(::Yito::Model::Order::Order)
          data = ::Yito::Model::Order::Order.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a order
        #
        app.put "/api/order", :allowed_usergroups => ['order_manager','booking_manager','staff']  do
          
          data_request = body_as_json(::Yito::Model::Order::Order)
                              
          if data = ::Yito::Model::Order::Order.get(data_request.delete(:id).to_i)     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes anorder 
        #
        app.delete "/api/order", :allowed_usergroups => ['order_manager','staff']  do
        
          data_request = body_as_json(::Yito::Model::Order::Order)
          
          key = data_request.delete(:id).to_i
          
          if data = ::Yito::Model::Order::Order.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end

        #
        # Add an order item
        #
        app.post '/api/order/order-item', :allowed_usergroups => ['order_manager','staff']  do 

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          if order = ::Yito::Model::Order::Order.get(data_request[:order_id])
            ::Yito::Model::Order::OrderItem.transaction do |transaction|
              order_item = ::Yito::Model::Order::OrderItem.new 
              order_item.item_id = data_request[:item_id]
              order_item.item_description = data_request[:item_description]
              order_item.item_price_description = data_request[:item_price_description]
              order_item.date = data_request[:date]
              order_item.time = data_request[:time]
              order_item.item_price_type = data_request[:item_price_type]
              order_item.quantity = data_request[:quantity]
              order_item.item_unit_cost = data_request[:item_unit_cost]
              order_item.item_cost = data_request[:item_cost]
              order_item.notes = data_request[:notes]
              order_item.order = order
              order_item.save
              order.total_cost += order_item.item_cost
              order.total_pending += order_item.item_cost 
              order.save
              transaction.commit 
              order.reload
            end
            content_type :json 
            order.to_json 
          else
            status 404
          end

        end

        #
        # Update an order item
        #
        app.put '/api/order/order-item', :allowed_usergroups => ['order_manager','staff']  do 

          request.body.rewind
          data_request = JSON.parse(URI.unescape(request.body.read))
          data_request.symbolize_keys!

          if order_item = ::Yito::Model::Order::OrderItem.get(data_request[:id])
            order = order_item.order
            ::Yito::Model::Order::OrderItem.transaction do |transaction|
              old_item_cost = order_item.item_cost
              order_item.item_id = data_request[:item_id]
              order_item.item_description = data_request[:item_description]
              order_item.item_price_description = data_request[:item_price_description]
              order_item.date = data_request[:date]
              order_item.time = data_request[:time]
              order_item.item_price_type = data_request[:item_price_type]              
              order_item.quantity = data_request[:quantity]
              order_item.item_unit_cost = data_request[:item_unit_cost]
              order_item.item_cost = data_request[:item_cost]
              order_item.notes = data_request[:notes]
              order_item.save
              order.total_cost = order.total_cost - old_item_cost + order_item.item_cost
              order.total_pending = order.total_pending - old_item_cost + order_item.item_cost 
              order.save
              transaction.commit 
              order.reload
            end
            content_type :json 
            order.to_json 
          else
            status 404
          end

        end

        #
        # Delete an order item
        #
        app.delete '/api/order/order-item/:id', :allowed_usergroups => ['order_manager','staff']  do 
          if order_item = ::Yito::Model::Order::OrderItem.get(params[:id])
            order = order_item.order
            order_item_cost = order_item.item_cost
            order_item.destroy 
            order.total_cost = order.total_cost - order_item_cost 
            order.total_pending = order.total_pending - order_item_cost
            order.save            
            order.reload 
            content_type :json
            order.to_json
          else
            status 404
          end
        end


        #
        # Allow order total payment
        #
        app.post '/api/order/allow-payment/:order_id', 
          :allowed_usergroups => ['order_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:order_id].to_i)
            order.force_allow_payment = true
            order.save
            content_type :json
            order.to_json
          else
            status 404
          end

        end

        #
        # Not allow order total payment
        #
        app.post '/api/order/not-allow-payment/:order_id', 
          :allowed_usergroups => ['order_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:order_id].to_i)
            order.force_allow_payment = false
            order.save
            content_type :json
            order.to_json
          else
            status 404
          end

        end

        #
        # Allow order deposit payment
        #
        app.post '/api/order/allow-deposit-payment/:order_id', 
          :allowed_usergroups => ['order_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:order_id].to_i)
            order.force_allow_deposit_payment = true
            order.save
            content_type :json
            order.to_json
          else
            status 404
          end

        end

        #
        # Not allow order deposit payment
        #
        app.post '/api/order/not-allow-deposit-payment/:order_id', 
          :allowed_usergroups => ['order_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:order_id].to_i)
            order.force_allow_deposit_payment = false
            order.save
            content_type :json
            order.to_json
          else
            status 404
          end

        end

        #
        # Register a booking charge
        #
        app.post '/api/order/charge', :allowed_usergroups => ['bookings_manager','staff'] do

          request.body.rewind
          data = JSON.parse(URI.unescape(request.body.read))
          data.symbolize_keys! 

          if order = ::Yito::Model::Order::Order.get(data[:id])
            
            order.transaction do  
              charge = Payments::Charge.new
              charge.date = data[:date]
              charge.amount = data[:amount]
              charge.payment_method_id = data[:payment_method_id]
              charge.status = :pending
              charge.currency = SystemConfiguration::Variable.get_value('payments.default_currency', 'EUR')
              charge.save
              order_charge = ::Yito::Model::Order::OrderCharge.new
              order_charge.order = order
              order_charge.charge = charge
              order_charge.save
              charge.update(:status => :done)
              order.reload
            end
            content_type :json
            status 200
            order.to_json
          else
            status 404
          end

        end

        # ------------ Send the notification emails ----------------------

        #
        # Request received
        #
        app.post '/api/order/send-customer-req-notification/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:id].to_i) and 
             order.status != :cancelled
            order.notify_request_to_customer
            content_type :json
            order.to_json
          else
            status 404
          end

        end

        #
        # Request received (with online payment)
        #
        app.post '/api/order/send-customer-req-notification-pay/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:id].to_i) and 
             order.status != :cancelled and 
             (order.force_allow_payment or order.force_allow_deposit_payment)
            order.notify_request_to_customer_pay_now
            content_type :json
            order.to_json
          else
            status 404
          end

        end

        #
        # Request confirmed
        #
        app.post '/api/order/send-customer-conf-notification/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:id].to_i) and
             order.status != :pending_confirmation and 
             order.status != :cancelled
            order.notify_customer
            content_type :json
            order.to_json
          else
            status 404
          end

        end        

        #
        # Payment enabled
        #
        app.post '/api/order/send-customer-pay-enabled/:id' , :allowed_usergroups => ['booking_manager', 'staff'] do

          if order=::Yito::Model::Order::Order.get(params[:id].to_i) and
             order.status != :cancelled
            order.notify_customer_payment_enabled
            content_type :json
            order.to_json
          else
            status 404
          end

        end  


      end
    end
  end
end