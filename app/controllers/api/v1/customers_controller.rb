module Api
  module V1
    class CustomersController < ApplicationController
      include ActionController::HttpAuthentication::Token
      
      before_action :authenticate_editor
      before_action :set_customer, only: %i[ show update destroy ]
   
      # GET /customers
      def index

        @customers = Customer.all
        filter_params.each do |key, value| 
          @customers = @customers.where(key => value) if value.present?
        end
        render json: CustomersRepresenter.new(@customers).as_json
      end
    
      # GET /customers/:id
      def show
        render json: CustomerRepresenter.new(@customer).as_json
      end
    
      # POST /customers
      def create
        customer = Customer.new(customer_params.merge(editor_id: @editor_id))
        if customer.save
          render json: CustomerRepresenter.new(customer).as_json, status: :created
        else
          render json: customer.errors, status: :unprocessable_entity
        end
      end
    
      # PATCH/PUT /customers/:id
      def update
        if @customer.update(customer_params)
          render json: CustomerRepresenter.new(@customer).as_json
        else
          render json: @customer.errors, status: :unprocessable_entity
        end
      end
    
      # DELETE /customers/:id
      def destroy
        @customer.destroy!
        head :no_content
      end
    
      private
        def authenticate_editor
          token, _options = token_and_options(request)
          @editor_id = AuthenticationTokenService.decode(token)
          Editor.find(@editor_id)
          rescue  ActiveRecord::RecordNotFound
            render json: "unauthorized request: No User(editor) is associated with this token", status: :unauthorized
          rescue JWT::DecodeError
            render json: "unauthorized request: JWT is invalid or not provided at all", status: :unauthorized
        end

        def set_customer
          begin
            @customer = Customer.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Record not found" }, status: :not_found
          end
        end
        # Only allow a list of trusted parameters through.
        def customer_params
          params.require(:customer).permit(:name, :phone)
        end

        def filter_params
          params.slice(:editor_id, :name, :phone)
        end
    end        
  end
end
