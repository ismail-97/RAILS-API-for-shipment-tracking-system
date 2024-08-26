module Api 
  module V1
    class ShipmentsController < ApplicationController
      include ActionController::HttpAuthentication::Token

      before_action :authenticate_editor, only: [:create, :destroy, :update, :index]
      before_action :set_shipment, only: [:show, :destroy, :update]
      
      # GET /shipments
      def index
        @shipments = Shipment.all
        filter_params.each do |key, value| 
          @shipments = @shipments.where(key => value) if value.present?
        end
        render json: ShipmentsRepresenter.new(@shipments).as_json
      end
    
      # GET /shipments/:id
      def show
        render json: ShipmentRepresenter.new(@shipment).as_json
      end
    
      # POST /shipments
      def create
        shipment = Shipment.new(shipment_params.merge(editor_id: @editor_id))
        if shipment.save
          render json: ShipmentRepresenter.new(shipment).as_json, status: :created
        else
          render json: shipment.errors, status: :unprocessable_entity
        end
      end
    
      # PATCH/PUT /shipments/:id
      def update
    
        if @shipment.update(shipment_params)
          render json: ShipmentRepresenter.new(@shipment).as_json
        else
          render json: @shipment.errors, status: :unprocessable_entity
        end
      end
    
      # DELETE /shipments/:id
      def destroy
        @shipment.destroy!
        head :no_content
      end
    
      private
        def authenticate_editor
          token, _options = token_and_options(request)
          @editor_id = AuthenticationTokenService.decode(token)
          @user = Editor.find(@editor_id)
          rescue  ActiveRecord::RecordNotFound
            render json: "unauthorized request: No User(editor) is associated with this token", status: :unauthorized
          rescue JWT::DecodeError
            render json: "unauthorized request: JWT is invalid or not provided at all", status: :unauthorized
        end
        
        def set_shipment
          begin
            @shipment = Shipment.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Record not found" }, status: :not_found
          end
        end
    
        # Only allow a list of trusted parameters through.
        def shipment_params
          params.require(:shipment).permit(:items_number, :weight, :contents, :status, :customer_id, :direction, :total, :flight_id)
        end

        def filter_params
          params.slice(:editor_id, :customer_id, :items_number, :weight, :contents, :status, :direction, :total, :flight_id)
        end
    end        
  end
end

