require 'ysd-plugins' unless defined?Plugins::Plugin
require 'ysd_plugin_order_extension'

Plugins::SinatraAppPlugin.register :order do

   name=        'order'
   author=      'yurak sisa'
   description= 'Order integration'
   version=     '0.1'
   
   hooker       Huasi::OrderExtension   
   sinatra_extension Sinatra::YitoExtension::Order
   sinatra_extension Sinatra::YitoExtension::OrderManagement
   sinatra_extension Sinatra::YitoExtension::OrderManagementRESTApi   

end