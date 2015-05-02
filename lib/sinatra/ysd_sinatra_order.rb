module Sinatra
  module YitoExtension
    module Order
      def self.registered(app)

        app.settings.views = Array(app.settings.views).push(
          File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 
          'views')))
        app.settings.translations = Array(app.settings.translations).push(File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'i18n')))      

        #
        # Shows an order: To be managed by the customer
        #   
        app.get '/p/myorder/:id/?*' do
          if order = ::Yito::Model::Order::Order.get_by_free_access_id(params[:id])
            locals = {:order => order}
             load_page :order, :locals => locals
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

      end
    end
  end
end