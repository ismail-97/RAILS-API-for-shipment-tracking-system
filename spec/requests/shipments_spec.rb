require 'rails_helper'

describe 'Shipments API', type: :request do
    let(:editor) {FactoryBot.create(:editor, name: "ismail", email: "ismailkamal@gmail.com", password: '123456', super_editor: true)}
    let(:customer) {FactoryBot.create(:customer, name: "ismail", phone: "1010101010", editor_id: editor.id)}
    let(:traveler) {FactoryBot.create(:traveler, name: "khaled swailem", phone: "1099929132", editor_id: editor.id)}
    let (:flight) {FactoryBot.create(:flight, flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', traveler_id: traveler.id, trip_type: 'return')}

    let(:valid_attributes) {
        [
          {direction: 'tr-eg', total: 500, customer_id: customer.id, editor_id: editor.id, flight_id: flight.id},
          {direction: 'tr-eg', total: 200, customer_id: customer.id, editor_id: editor.id, flight_id: flight.id}
        ]
      }

    let(:invalid_attributes) {
        [
          {flight_id: flight.id, editor_id: editor.id, direction: 'tr-eg', total: 500}, # absence of customer_id
          {flight_id: flight.id, editor_id: editor.id, customer_id: customer.id, total: 300}, # absence of direction
          {flight_id: flight.id, editor_id: editor.id, customer_id: customer.id, direction: 'tr-eg'}, # absence of total
          {editor_id: editor.id, customer_id: customer.id, direction: 'tr-eg', total: 500}, # absence of flight_id
        ]
      }

    let(:headers) {
        {        
            "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
        }    
    }

    before (:each) do
        Customer.delete_all
        Shipment.delete_all
    end 

    describe 'GET /shipments' do

        before do
            FactoryBot.create(:shipment, valid_attributes[0])
            FactoryBot.create(:shipment, valid_attributes[1])    
        end

        context 'without query parameters' do
            before do
                get '/api/v1/shipments', headers: headers  
            end

            it 'returns all shipments' do
                expect(JSON.parse(response.body).size).to eq(2)
            end           
            
            it 'returns a 200 Success status' do
                expect(response).to have_http_status(:success)         
            end        
        end

        context 'with query parameters' do
            it 'returns a specific shipment depending on query parameters' do
                get '/api/v1/shipments',  headers: headers, params: {total: 500}    
                expect(JSON.parse(response.body).size).to eq(1)
                expect(response).to have_http_status(:success)         
                expect(response.body).to include({ id:12 }.merge(valid_attributes[0]).to_json)
            end     

            it 'does not apply filter on parameters which is not allowed via controller' do
                get '/api/v1/shipments',  headers: headers, params: {price: 578}    
                expect(JSON.parse(response.body).size).to eq(2)
                expect(response).to have_http_status(:success)         
            end
        end
        
        context 'missing authorization header ' do
            it 'returns a 401' do
                get '/api/v1/shipments', headers: {}  
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end 

    describe 'GET /shipments/:id' do
        let(:shipment) {FactoryBot.create(:shipment, valid_attributes[0])}
           
        it 'returns a specific shipment' do
            get "/api/v1/shipments/#{shipment.id}"  
            expect(JSON.parse(response.body).size).to eq(6)
            expect(response).to have_http_status(:success)         
            expect(response.body).to eq({ id:12 }.merge(valid_attributes[0]).to_json)
        end

        context 'with non existing shipment' do
            it 'returns a 404' do
                get "/api/v1/shipments/500"  
                expect(response).to have_http_status(:not_found)         
            end  
        end
    end
    
    describe 'POST /shipments' do
        before do
            post '/api/v1/shipments', 
            params: {shipment: valid_attributes[0]}, 
            headers: headers     
        end

        context 'with valid attributes' do
            it 'creates a new shipment' do
                expect(Shipment.count).to eq(1)
            end
    
            it 'returns a 201 Created status' do
                expect(response).to have_http_status(:created)
            end  
            
            it 'returns the created shipment attributes in the response' do
                expect(response.body).to include_json(valid_attributes[0])
            end
    
            context 'missing authorization header ' do
                it 'returns a 401' do
                    post '/api/v1/shipments', params: {shipment: valid_attributes[0]}, headers: {}
                    expect(response).to have_http_status(:unauthorized)         
                end
            end          
        end

        context 'with invalid attributes' do           
            it 'returns error when customer_id is absent' do
                post '/api/v1/shipments', 
                params: {shipment: invalid_attributes[0]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"customer" => ["must exist"]})
            end

            it 'returns error when direction is absent' do
                post '/api/v1/shipments', 
                params: {shipment: invalid_attributes[1]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"direction" => ["can't be blank"]})
            end

            it 'returns error when total is absent' do
                post '/api/v1/shipments', 
                params: {shipment: invalid_attributes[2]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"total" => ["can't be blank"]})
            end

            it 'returns error when flight_id is absent' do
                post '/api/v1/shipments', 
                params: {shipment: invalid_attributes[3]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"flight" => ["must exist"]})
            end
        end

        context 'without authorization header ' do
            it 'returns a 401' do
                post '/api/v1/shipments', 
                params: {shipment: valid_attributes[0]}

                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end

    describe 'DELETE /shipments/:id' do
        let(:shipment) { FactoryBot.create(:shipment, valid_attributes[0]) }

        it 'deletes a shipment' do
            delete "/api/v1/shipments/#{shipment.id}", headers: headers      
            expect(Shipment.exists?(shipment.id)).to be_falsey
            expect(response).to have_http_status(:no_content)
        end
        
        context 'with non-existing shipment' do
            it 'returns a 404' do
                delete "/api/v1/shipments/500", headers: headers      
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header ' do
            it 'returns a 401' do
                delete "/api/v1/shipments/#{shipment.id}", headers: {}     
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end

    describe 'PUT /shipments/:id' do
        let(:shipment) { FactoryBot.create(:shipment, valid_attributes[0]) }

        it 'update a shipment' do 
            put "/api/v1/shipments/#{shipment.id}", 
            params: {shipment: {total: 200}},
            headers: headers

            expect(Shipment.exists?(shipment.id)).to be_truthy
            expect(response).to have_http_status(:ok)
            expect(response.body).to include_json(total: 200)
        end  

        context 'with invalid attributes' do           

            it 'returns error when customer_id is absent' do
                put "/api/v1/shipments/#{shipment.id}", 
                params: {shipment: {customer_id: " "}},
                headers: headers
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"customer" => ["must exist"]})
            end

            it 'returns error when total is absent' do
                put "/api/v1/shipments/#{shipment.id}", 
                params: {shipment: {total: " "}},
                headers: headers
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"total" => ["can't be blank"]})
            end

            it 'returns error when direction is absent' do
                put "/api/v1/shipments/#{shipment.id}", 
                params: {shipment: {direction: " "}},
                headers: headers
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"direction" => ["can't be blank"]})
            end
        end

        context 'with non-existing shipment' do
            it 'returns a 404' do
                put "/api/v1/shipments/500", 
                params: {shipment: {total: 200}},
                headers: headers

                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'missing authorization header ' do
            it 'returns a 401' do
                put "/api/v1/shipments/#{shipment.id}", headers: {}     
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end
end