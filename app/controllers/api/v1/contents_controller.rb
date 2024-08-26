module Api
  module V1
      class ContentsController < ApplicationController
          include ActionController::HttpAuthentication::Token

          before_action :set_shipment
          before_action :set_content, only: %i[ show update destroy]
          before_action :authenticate_editor

          def index
            @contents = Content.all
            filter_params.each do |key, value| 
              @contents = @contents.where(key => value) if value.present?
            end

            render json: ContentsRepresenter.new(@contents).as_json
          end

          def show 
            render json: ContentRepresenter.new(@content).as_json
          end

          def create
            content = Content.new(content_params)
            if content.save
              render json: ContentRepresenter.new(content).as_json, status: :created
            else
              render json: content.errors, status: :unprocessable_entity
            end         
          end

          def update
            if @content.update(content_params)
              render json: ContentRepresenter.new(@content).as_json
            else
              render json: @content.errors, status: :unprocessable_entity
            end
          end

          def destroy
            @content.destroy!
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

            def set_content
              begin
                @content = Content.find(params[:id])
              rescue ActiveRecord::RecordNotFound
                render json: { error: "content record not found" }, status: :not_found
              end
            end

            def set_shipment
              begin
                @shipment = Shipment.find(params[:shipment_id])
              rescue ActiveRecord::RecordNotFound
                render json: { error: "shipment record not found" }, status: :not_found
              end
            end

            def content_params
              params.require(:content).permit(:content_type, :weight, :kg_price, :items_number, :shipment_id)
            end

            def filter_params
              params.slice(:content_type, :weight, :kg_price, :items_number, :shipment_id)
            end
      end
  end
end
