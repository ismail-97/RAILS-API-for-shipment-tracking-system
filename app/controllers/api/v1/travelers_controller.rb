module Api
    module V1
        class TravelersController < ApplicationController
            include ActionController::HttpAuthentication::Token

            before_action :authenticate_editor
            before_action :authenticate_admin, only: %i[ create destroy update]
            before_action :set_traveler, only: %i[ show update destroy ]

            # GET /travelers
            def index

                @travelers = Traveler.all
                filter_params.each do |key, value| 
                    @travelers = @travelers.where(key => value) if value.present?
                end
                render json: TravelersRepresenter.new(@travelers).as_json
            end
            
            # GET /travelers/:id
            def show
                render json: TravelerRepresenter.new(@traveler).as_json
            end
            
            # POST /travelers
            def create
                traveler = Traveler.new(traveler_params.merge(editor_id: @editor_id))
                if traveler.save
                    render json: TravelerRepresenter.new(traveler).as_json, status: :created
                else
                    render json: traveler.errors, status: :unprocessable_entity
                end
            end
            
            # PATCH/PUT /travelers/:id
            def update
                if @traveler.update(traveler_params)
                    render json: TravelerRepresenter.new(@traveler).as_json
                else
                    render json: @traveler.errors, status: :unprocessable_entity
                end
            end
            
            # DELETE /travelers/:id
            def destroy
                @traveler.destroy!
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

                def authenticate_admin
                    unless @user.super_editor
                      render json: "unauthorized request: this action is allowed only for admins", status: :unauthorized
                    end
                end

                def set_traveler
                begin
                    @traveler = Traveler.find(params[:id])
                rescue ActiveRecord::RecordNotFound
                    render json: { error: "Record not found" }, status: :not_found
                end
                end
                # Only allow a list of trusted parameters through.
                def traveler_params
                    params.require(:traveler).permit(:name, :phone)
                end

                def filter_params
                    params.slice(:editor_id, :name, :phone)
                end            
        end
    end
end