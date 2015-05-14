#require 'ysd_md_calendar' unless defined?Yito::Model::Calendar::Calendar

module Sinatra
  module YitoExtension
    module OrderManagementRESTApi

      def self.registered(app)

        #                    
        # Query orders
        #
        ["/api/orders","/api/orders/page/:page"].each do |path|
          
          app.post path, :allowed_usergroups => ['order_manager','staff']  do

            page = params[:page].to_i || 1
            limit = 12
            offset = (page-1) * 12

            data  = ::Yito::Model::Order::Order.all(:limit => limit, :offset => offset, :order => [:creation_date.desc])
            total = ::Yito::Model::Order::Order.count
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get orders
        #
        app.get "/api/orders", :allowed_usergroups => ['order_manager','staff']  do

          data = ::Yito::Model::Order::Order.all

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get an order
        #
        app.get "/api/order/:id", :allowed_usergroups => ['order_manager','staff']  do
        
          data = ::Yito::Model::Order::Order.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a new order
        #
        app.post "/api/order", :allowed_usergroups => ['order_manager','staff']  do
        
          data_request = body_as_json(::Yito::Model::Order::Order)
          data = ::Yito::Model::Order::Order.create(data_request)
         
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a order
        #
        app.put "/api/order", :allowed_usergroups => ['order_manager','staff']  do
          
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


      end
    end
  end
end