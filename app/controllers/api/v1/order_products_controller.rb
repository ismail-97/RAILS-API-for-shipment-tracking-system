module Api 
  module V1 
    class OrderProductsController < ApplicationController
      include ActionController::HttpAuthentication::Token

      before_action :authenticate_editor
      before_action :set_order_product, only: %i[ show update destroy]
      before_action :set_order, only: %i[ create update ]
      before_action :check_quantity, only: %i[ create update]

      def index
        @order_products = OrderProduct.all
        filter_params.each do |key, value| 
          @order_products = @order_products.where(key => value) if value.present?
        end
        render json: OrderProductsRepresenter.new(@order_products).as_json
      end

      def show
        render json: OrderProductRepresenter.new(@order_product).as_json
      end

      def create
        order_product = OrderProduct.new(order_product_params)
        if order_product.save
          render json: OrderProductRepresenter.new(order_product).as_json, status: :created             
        else
          render json: order_product.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @order_product.destroy!
        head :no_content
      end

      def update
        if @order_product.update(order_product_params)
          render json: OrderProductRepresenter.new(@order_product).as_json
        else
          render json: @order_product.errors, status: :unprocessable_entity
        end
      end
      
      private

        def authenticate_admin
          unless @user.super_editor
            render json: "unauthorized request: this action is allowed only for admins", status: :unauthorized
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

        def set_order_product
          begin
            @order_product = OrderProduct.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "order product record not found" }, status: :not_found
          end
        end

        def set_order
          begin
            if @order_product
              @product = Product.find(@order_product.product_id)
            else
              @product = Product.find(order_product_params[:product_id])
            end
          rescue
            render json: { error: "product record not found" }, status: :not_found
          end
        end

        def order_product_params
          params.require(:order_product).permit(:quantity, :price, :order_id, :product_id)
        end

        def filter_params
          params.slice(:quantity, :price, :order_id, :product_id)
        end

        def check_quantity
          if order_product_params[:quantity].to_f > @product.stock
            render json: { error: "Quantity exceeds available stock" }, status: :unprocessable_entity
          end
        end
    end
  end
end
