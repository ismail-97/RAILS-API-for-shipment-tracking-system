module Api
  module V1
    class EditorsController < ApplicationController
      include ActionController::HttpAuthentication::Token

      before_action :set_editor, only: %i[ show update destroy ]
      before_action :authenticate_editor
      before_action :authenticate_admin, only: %i[ index create destroy update ]

      def index
          @editors = Editor.all
          filter_params.each do |key, value| 
            @editors = @editors.where(key => value) if value.present?
          end
          render json: EditorsRepresenter.new(@editors).as_json
      end

      def show
          render json: EditorRepresenter.new(@editor).as_json
      end

      def create
        editor = Editor.new(editor_params)
        if(editor.save)
          render json: EditorRepresenter.new(editor).as_json, status: :created
        else
          render json: editor.errors, status: :unprocessable_entity
        end
      end

      def update
        if @editor.update(editor_params)
          render json: EditorRepresenter.new(@editor).as_json
        else
          render json: @editor.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @editor.destroy!
        head :no_content
      end    
      
      private
        def authenticate_admin
          unless @user&.super_editor
            render json: { error: "unauthorized request: this action is allowed only for admins"}, status: :unauthorized
          end
        end

        def authenticate_editor
          token, _options = token_and_options(request)
          @editor_id = AuthenticationTokenService.decode(token)
          @user = Editor.find(@editor_id)
          rescue  ActiveRecord::RecordNotFound
            render json: { error: "unauthorized request: No User(editor) is associated with this token"}, status: :unauthorized
          rescue JWT::DecodeError
            render json: { error: "unauthorized request: JWT is invalid or not provided at all"}, status: :unauthorized
        end

        def set_editor
          begin
            @editor = Editor.find(params[:id])
          rescue ActiveRecord::RecordNotFound
            render json: { error: "Record not found" }, status: :not_found
          end
        end

        def editor_params
          params.require(:editor).permit(:name, :email, :password, :super_editor)
        end

        def filter_params
          params.slice(:email, :name, :super_editor)
        end
    end
  end
end


