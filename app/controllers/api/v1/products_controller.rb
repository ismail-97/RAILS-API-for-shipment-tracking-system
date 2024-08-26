module Api
  module V1 
    class ProductsController < ApplicationController
      include ActionController::HttpAuthentication::Token

      before_action :set_product, only: [:show, :destroy, :update]
      before_action :authenticate_editor

      def index
        @products = Product.all
        filter_params.each do |key, value| 
          @products =  @products.where(key => value) if value.present?
        end
        render json: ProductsRepresenter.new(@products).as_json
      end

      def show
        render json: ProductRepresenter.new(@product).as_json              
      end

      def create
        product = Product.new(product_params)
        if product.save
          render json: ProductRepresenter.new(product).as_json, status: :created             
        else
          render json: product.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @product.destroy!
        head :no_content
      end

      def update
        if @product.update(product_params)
          render json: ProductRepresenter.new(@product).as_json
        else
          render json: @product.errors, status: :unprocessable_entity
        end
      end

      private
        def set_product
          begin
            @product = Product.find(params[:id])
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
          params.slice(:product_type, :stock, :price)
        end 

        def product_params
          params.require(:product).permit(:product_type, :stock, :price)
        end
    end
  end
end
