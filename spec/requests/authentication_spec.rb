require 'rails_helper'

describe "Authentication" , type: :request do
    let(:editor) { FactoryBot.create(:editor, email: 'ismail@gmail.com', password: '123456')}
    describe 'POST /login' do
        it 'authenticates the customer' do
            post '/api/v1/login', params: {email: editor.email, password: '123456'}
            expect(response).to have_http_status(:created)
            expect(JSON.parse(response.body)).to eq({
                "token" => "eyJhbGciOiJIUzI1NiJ9.eyJlZGl0b3JfaWQiOjF9.TxCagZHM4YADyV7eiA0AxukEGw-EQlL-YNAJzAmfEMU"
            })
        end

        it 'returns error when username is missing' do
            post '/api/v1/login', params: {password: '123456'}
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({
                'error' => 'param is missing or the value is empty: email'
            })

        end

        it 'returns error when password is missing' do
            post '/api/v1/login', params: {email: 'ismail@gmail.com'}
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({
                'error' => 'param is missing or the value is empty: password'
            })
        end

        it 'returns error when password is incorrect' do
            post '/api/v1/login', params: {email: editor.email, password: 'incorrect'} 
            expect(response).to have_http_status(:unauthorized)
            # expect(JSON.parse(response.body)).to eq({
            #     'error' => 'password is incorrect'
            # })
        end
    end
end