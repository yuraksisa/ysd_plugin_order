module Sinatra
  module YitoExtension
    module OrderManagement

      def self.registered(app)

        #
        # Order management page
        #
        app.get '/admin/order/orders/?*', :allowed_usergroups => ['order_manager','staff'] do 

          locals = {:order_page_size => 12}
          load_em_page :order_management, nil, false, :locals => locals

        end

      end

    end
  end
end