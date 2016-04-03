#require 'ysd_md_calendar' unless defined?Yito::Model::Calendar::Calendar

module Sinatra
  module YitoExtension
    module InformationRequestManagementRESTApi

      def self.registered(app)

        #                    
        # Query information-request
        #
        ["/api/information-requests","/api/information-requests/page/:page"].each do |path|
          
          app.post path, :allowed_usergroups => ['order_manager','booking_manager','staff'] do

            page = params[:page].to_i || 1
            limit = 12
            offset = (page-1) * 12

            data  = ::Yito::Model::Order::RequestInformation.all(:limit => limit, :offset => offset, :order => [:creation_date.desc])
            total = ::Yito::Model::Order::RequestInformation.count
          
            content_type :json
            {:data => data, :summary => {:total => total}}.to_json
          
          end
        
        end
        
        #
        # Get information-request
        #
        app.get "/api/information-requests", :allowed_usergroups => ['order_manager','booking_manager','staff'] do

          data = ::Yito::Model::Order::RequestInformation.all

          status 200
          content_type :json
          data.to_json

        end

        #
        # Get an information-request
        #
        app.get "/api/information-request/:id", :allowed_usergroups => ['order_manager','booking_manager','staff'] do
        
          data = ::Yito::Model::Order::RequestInformation.get(params[:id].to_i)
          
          status 200
          content_type :json
          data.to_json
        
        end
        
        #
        # Create a new information-request (public)
        #
        app.post "/api/public/orders/information-request" do
        
          data_request = body_as_json(::Yito::Model::Order::RequestInformation)
          
          data = ::Yito::Model::Order::RequestInformation.new
          data.subject = data_request[:subject]
          data.comments = data_request[:comments]
          data.customer_name = data_request[:customer_name]
          data.customer_surname = data_request[:customer_surname]
          data.customer_phone = data_request[:customer_phone]
          data.customer_email = data_request[:customer_email]
          data.source = 'web'
          data.created_by_manager = false
          data.init_user_agent_data(request.env["HTTP_USER_AGENT"])
          
          begin
            data.save
          rescue
            p "Error saving information request. #{data.inspect} #{data.errors.inspect}"
            raise error
          end
          
          status 200
         
        end

        #
        # Create a new information-request
        #
        app.post "/api/information-request", :allowed_usergroups => ['order_manager','booking_manager','staff'] do
        
          data_request = body_as_json(::Yito::Model::Order::RequestInformation)
          data = ::Yito::Model::Order::RequestInformation.create(data_request)
          data.created_by_manager = true
          data.init_user_agent_data(request.env["HTTP_USER_AGENT"])
          
          status 200
          content_type :json
          data.to_json          
        
        end
        
        #
        # Updates a information-request
        #
        app.put "/api/information-request", :allowed_usergroups => ['order_manager','booking_manager','staff'] do
          
          data_request = body_as_json(::Yito::Model::Order::RequestInformation)
                              
          if data = ::Yito::Model::Order::RequestInformation.get(data_request.delete(:id).to_i)     
            data.attributes=data_request  
            data.save
          end
      
          content_type :json
          data.to_json        
        
        end
        
        #
        # Deletes anorder 
        #
        app.delete "/api/information-request", :allowed_usergroups => ['order_manager','booking_manager','staff'] do
        
          data_request = body_as_json(::Yito::Model::Order::RequestInformation)
          
          key = data_request.delete(:id).to_i
          
          if data = ::Yito::Model::Order::RequestInformation.get(key)
            data.destroy
          end
          
          content_type :json
          true.to_json
        
        end


      end
    end
  end
end