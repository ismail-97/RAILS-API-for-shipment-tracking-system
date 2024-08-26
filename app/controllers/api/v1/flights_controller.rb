module Api
  module V1
    class FlightsController < ApplicationController
      include ActionController::HttpAuthentication::Token

      before_action :authenticate_editor
      before_action :authenticate_admin, only: %i[ create destroy update]
      before_action :set_flight, only: [:show, :destroy, :update]

      # GET /flights
      def index
        @flights = Flight.all
        filter_params.each do |key, value| 
            @flights = @flights.where(key => value) if value.present?
        end
        render json: FlightsRepresenter.new(@flights).as_json  
      end

      # GET /flights/:id
      def show
        render json: FlightRepresenter.new(@flight).as_json
      end

      # POST /flights
      def create
        flight = Flight.new(flight_params)
        if flight.save
            render json: FlightRepresenter.new(flight).as_json, status: :created
        else
            render json: flight.errors, status: :unprocessable_entity
        end
      end

      def update
        if @flight.update(flight_params)
          render json: FlightRepresenter.new(@flight).as_json
        else
          render json: @flight.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @flight.destroy!
        head :no_content
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
        
        def set_flight
          begin
            @flight = Flight.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Record not found" }, status: :not_found
          end
        end
    
        # Only allow a list of trusted parameters through.
        def flight_params
          params.require(:flight).permit(:flight_date, :ticket_no, :ticket_price, :airline, :traveler_id, :trip_type)
        end

        def filter_params
          params.slice(:flight_date, :ticket_no, :ticket_price, :airline, :traveler_id, :trip_type)
        end
    end
  end
end

