module Api 
    module V1
      class AuthenticationController < ApplicationController
        class AuthenticationError < StandardError; end
        rescue_from ActionController::ParameterMissing, with: :parameter_missing
        rescue_from AuthenticationError, with: :handle_unauthenticated

        def login
            password = params.require(:password)

            raise AuthenticationError unless editor&.authenticate(password)
            token = AuthenticationTokenService.encode(editor.id)

            render json: { token: token }, status: :created
        end

        def logout
            # should create database table for invalid tokens
            # start
            # end
            render json: { message: "Logged out successfully" }, status: :ok
        end
            
        private
            def editor
                @editor ||= Editor.find_by(email: params.require(:email))                              
            end
            def parameter_missing(e)
                render json: { error: e.message }, status: :unprocessable_entity
            end

            def handle_unauthenticated
                head :unauthorized  
            end
      end
    end
end