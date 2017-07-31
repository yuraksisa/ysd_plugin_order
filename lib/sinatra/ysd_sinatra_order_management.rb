module Sinatra
  module YitoExtension
    module OrderManagement

      def self.registered(app)

        #
        # Order management page
        #
        app.get '/admin/order/orders/?*', :allowed_usergroups => ['order_manager', 'booking_manager', 'staff'] do 

          @booking_item_family = ::Yito::Model::Booking::ProductFamily.get(SystemConfiguration::Variable.get_value('booking.item_family'))
          locals = {:order_page_size => 12}
          load_em_page :order_management, nil, false, :locals => locals

        end

        #
        # Add new order item : Step 1 - Choose activity
        #
        app.get '/admin/order/new-order-item-step-1/?*', :allowed_usergroups => ['order_manager', 'booking_manager', 'staff'] do  

          if params[:order]
            if @order = ::Yito::Model::Order::Order.get(params[:order])
              @activities = ::Yito::Model::Booking::Activity.all(active: true)
              session.delete(:backoffice_new_order_item_activity_date_id)
              session.delete(:backoffice_new_order_item_date)
              session.delete(:backoffice_new_order_item_turn)
              load_page(:new_order_line_step_1)
            else
              logger.error("Order #{params[:order]} not found")
              status 404
            end
          else
            logger.error("Not order parameter")
            status 404
          end

        end
       
        #
        # Add new order item : Step 2 - Select dates and quantity
        #
        app.post '/admin/order/new-order-item-step-2/?*', :allowed_usergroups => ['order_manager', 'booking_manager', 'staff'] do

          order_id = params[:order_id]
          activity_id = params[:activity_id]

          if order_id and activity_id
            if @order = ::Yito::Model::Order::Order.get(order_id)
              if @activity = ::Yito::Model::Booking::Activity.get(activity_id)
                @occupation = {total_occupation: 0, occupation_detail: {}, occupation_capacity: @activity.capacity}
                if session[:backoffice_new_order_item_activity_date_id]
                  @activity_date_id = session[:backoffice_new_order_item_activity_date_id]
                  if @activity_date = ::Yito::Model::Booking::ActivityDate.get(@activity_date_id)
                    @occupation = @activity.occupation(@activity_date.date_from, @activity_date.time_from)
                  end
                elsif session[:backoffice_new_order_item_date] or session[:backoffice_new_order_item_turn]
                  @date = session[:backoffice_new_order_item_date] ? Date.strptime(session[:backoffice_new_order_item_date],'%Y-%m-%d') : nil
                  @time = session[:backoffice_new_order_item_turn] 
                  if @date and !@date.nil? and @time and !@time.nil?
                    @occupation = @activity.occupation(@date, @time)
                  end
                end
                load_page(:new_order_line_step_2)
              else
                logger.error("Activity #{activity_id} not found")
                status 404
              end              
            else
              logger.error("Order #{order_id} not found")
              status 404
            end
          else
            logger.error("order_id or activity_id empty")
            status 404
          end

        end

        #
        # Select a date
        #
        app.post '/admin/order/new-order-item-select-date/?*', :allowed_usergroups => ['order_manager', 'booking_manager', 'staff'] do

          if @order = ::Yito::Model::Order::Order.get(params[:order_id])
            if @activity = ::Yito::Model::Booking::Activity.get(params[:activity_id])
              @occupation = {total_occupation: 0, occupation_detail: {}, occupation_capacity: @activity.capacity}
              if params[:activity_date_id]
                @activity_date_id = params[:activity_date_id]
                if @activity_date = ::Yito::Model::Booking::ActivityDate.get(@activity_date_id)
                  @occupation = @activity.occupation(@activity_date.date_from, @activity_date.time_from)
                end
                session[:backoffice_new_order_item_activity_date_id] = @activity_date_id
              elsif params[:date] or params[:turn]
                @date = params[:date] ? Date.strptime(params[:date],'%Y-%m-%d') : nil
                if params[:turn] && !params[:turn].to_s.empty?
                  @time = params[:turn]
                else
                  @time = nil
                end
                if @date and !@date.nil? and @time and !@time.nil?
                  @occupation = @activity.occupation(@date, @time)
                end
                session[:backoffice_new_order_item_date] = @date
                session[:backoffice_new_order_item_turn] = @time
              end

              load_page(:new_order_line_step_2)           
            else
              logger.error("Activity #{activity_id} not found")
              status 404
            end
          else
            logger.error("Order #{order_id} not found")
          end

        end


        #
        # Add an activity
        #
        app.post '/admin/order/new-order-item-add-activity/?*', :allowed_usergroups => ['order_manager', 'booking_manager', 'staff'] do

          activity_id = params[:activity_id]
          date = time = description = nil

          if @order = ::Yito::Model::Order::Order.get(params[:order_id])
            if params[:activity_date_id]
              if activity_date = ::Yito::Model::Booking::ActivityDate.get(params[:activity_date_id])
                date = activity_date.date_from
                time = activity_date.time_from
                description = activity_date.description
              end
            else
              date = DateTime.strptime(params[:date],'%Y-%m-%d')
              time = params[:turn]
            end
            quantity_rate_1 = params[:quantity_rate_1].to_i
            quantity_rate_2 = params[:quantity_rate_2].to_i
            quantity_rate_3 = params[:quantity_rate_3].to_i
            custom_customers_pickup_place = params[:custom_customers_pickup_place].to_bool if params.has_key?('custom_customers_pickup_place')
            customers_pickup_place = params[:customers_pickup_place] if params.has_key?('customers_pickup_place')

            if @activity = ::Yito::Model::Booking::Activity.get(activity_id)
              activity_options = {
                  request_customer_information: @activity.request_customer_information,
                  request_customer_address: @activity.request_customer_address,
                  request_customer_document_id: @activity.request_customer_document_id,
                  request_customer_phone: @activity.request_customer_phone,
                  request_customer_email: @activity.request_customer_email,
                  request_customer_height: @activity.request_customer_height,
                  request_customer_weight: @activity.request_customer_weight,
                  request_customer_allergies_intolerances: @activity.request_customer_allergies_intolerances,
                  uses_planning_resources: @activity.uses_planning_resources
              }
              activity_name = @activity.name
              activity_name << " (#{description})" unless description.nil?           
              ::Yito::Model::Order::Order.transaction do 
                begin
                  # Appends items
                  if !quantity_rate_1.nil? and quantity_rate_1 > 0
                    @order.add_item(date, 
                                  time, 
                                  @activity.code, 
                                  activity_name,
                                  1,
                                  quantity_rate_1,
                                  @activity.rates(date)[1][1],
                                  @activity.price_1_description,
                                  custom_customers_pickup_place,
                                  customers_pickup_place,
                                  @activity.price_1_affects_capacity ? activity_options : {})
                  end

                  if !quantity_rate_2.nil? and quantity_rate_2 > 0
                    @order.add_item(date, 
                                  time, 
                                  @activity.code, 
                                  activity_name,
                                  2,
                                  quantity_rate_2,
                                  @activity.rates(date)[2][1],
                                  @activity.price_2_description,
                                  custom_customers_pickup_place,
                                  customers_pickup_place,
                                  @activity.price_2_affects_capacity ? activity_options : {}) 
                  end

                  if !quantity_rate_3.nil? and quantity_rate_3 > 0
                    @order.add_item(date, 
                                  time, 
                                  @activity.code, 
                                  activity_name,
                                  3,
                                  quantity_rate_3,
                                  @activity.rates(date)[3][1],
                                  @activity.price_3_description,
                                  custom_customers_pickup_place,
                                  customers_pickup_place,
                                  @activity.price_3_affects_capacity ? activity_options : {})               
                  end
                rescue DataMapper::SaveFailureError => error
                  p "Error adding item(s) to shopping_cart. #{@shopping_cart.inspect} #{@shopping_cart.errors.inspect}"
                  raise error
                end
              end
              redirect "/admin/order/orders/#{@order.id}"
            else
              logger.error("Activity #{@activity.id} not found")
              status 404
            end

          else
            logger.error("Order #{@order.id} not found")
            status 404
          end 

        end


      end

    end
  end
end