module Api
    module V1
        class FlightExpensesController < ApplicationController
            include ActionController::HttpAuthentication::Token

            before_action :set_flight
            before_action :set_flight_expense, only: %i[ show update destroy]
            before_action :authenticate_editor

            def index
              @flight_expenses = FlightExpense.all
              filter_params.each do |key, value| 
                @flight_expenses = @flight_expenses.where(key => value) if value.present?
              end

              render json: FlightExpensesRepresenter.new(@flight_expenses).as_json
            end

            def show 
              render json: FlightExpenseRepresenter.new(@flight_expense).as_json
            end

            def create
              flight_expense = FlightExpense.new(flight_expense_params)
              if flight_expense.save
                render json: FlightExpenseRepresenter.new(flight_expense).as_json, status: :created
              else
                render json: flight_expense.errors, status: :unprocessable_entity
              end         
            end

            def update
              if @flight_expense.update(flight_expense_params)
                render json: FlightExpenseRepresenter.new(@flight_expense).as_json
              else
                render json: @flight_expense.errors, status: :unprocessable_entity
              end
            end

            def destroy
              @flight_expense.destroy!
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

              def set_flight_expense
                begin
                  @flight_expense = FlightExpense.find(params[:id])
                rescue ActiveRecord::RecordNotFound
                  render json: { error: "Flight expense record not found" }, status: :not_found
                end
              end

              def set_flight
                begin
                  @flight = Flight.find(params[:flight_id])
                rescue ActiveRecord::RecordNotFound
                  render json: { error: "Flight record not found" }, status: :not_found
                end
              end

              def flight_expense_params
                params.require(:flight_expense).permit(:expense_type, :amount, :flight_id, :direction)
              end

              def filter_params
                params.slice(:expense_type, :amount, :flight_id, :direction)
              end
        end
    end
end
