module Sinatra
  module YitoExtension
    module InformationRequestManagement

      def self.registered(app)

        #
        # Order management page
        #
        app.get '/admin/order/information-requests/?*', :allowed_usergroups => ['order_manager','staff'] do 

          locals = {:information_request_page_size => 12}
          load_em_page :request_information_management, nil, false, :locals => locals

        end

      end

    end
  end
end