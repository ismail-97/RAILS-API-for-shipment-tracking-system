module Api
    module V1
        class OrdersController < ApplicationController
            include ActionController::HttpAuthentication::Token
            
            before_action :set_order, only: [:show, :destroy, :update]
            before_action :authenticate_editor

            def index
              @orders = Order.all
              filter_params.each do |key, value| 
                @orders =  @orders.where(key => value) if value.present?
              end
              render json: OrdersRepresenter.new(@orders).as_json
            end

            def show
                render json: OrderRepresenter.new(@order).as_json              
            end

            def create
              order = Order.new(order_params)
              if order.save
                render json: OrderRepresenter.new(order).as_json, status: :created             
              else
                render json: order.errors, status: :unprocessable_entity
              end
            end

            def destroy
              @order.destroy!
              head :no_content
            end

            def update
              if @order.update(order_params)
                render json: OrderRepresenter.new(@order).as_json
              else
                render json: @order.errors, status: :unprocessable_entity
              end
            end

            private
              def set_order
                begin
                  @order = Order.find(params[:id])
                rescue ActiveRecord::RecordNotFound
                  render json: { error: "Record not found" }, status: :not_found
                end
              end

              def authenticate_editor
                token, _options = token_and_options(request)
                @editor_id = AuthenticationTokenService.decode(token)
                @user = Editor.find(@editor_id)
              rescue  ActiveRecord::RecordNotFound
                render json: "unauthorized request: No User(editor) is associated with this token", status: :unauthorized
              rescue JWT::DecodeError
                render json: "unauthorized request: JWT is invalid or not provided at all", status: :unauthorized
              end

              def filter_params
                params.slice(:order_date, :total, :customer_id)
              end 

              def order_params
                params.require(:order).permit(:order_date, :total, :customer_id)
              end
        end
    end
end
