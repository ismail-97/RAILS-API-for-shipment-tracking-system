require 'rails_helper'

RSpec.describe "Flights", type: :request do
  let(:editor) {FactoryBot.create(:editor, name: "ismail", email: "ismailkamal@gmail.com", password: '123456', super_editor: true)}
  let(:traveler1) {FactoryBot.create(:traveler, name: "khaled swailem", phone: "1099929132", editor_id: editor.id)}
  let(:traveler2) {FactoryBot.create(:traveler, name: "NAGAT ABDALLAH", phone: "5642562356", editor_id: editor.id)}

  let(:valid_attributes) {[
        {flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', traveler_id: traveler1.id, trip_type: 'return'},
        {flight_date: Date.new(2024, 8, 4), ticket_no: "077-2445660520", ticket_price: 365, airline: 'egyptair', traveler_id: traveler2.id, trip_type: 'return'},
      ]
    }

  let(:invalid_attributes) {[
        {ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', traveler_id: traveler1.id, trip_type: 'return'}, #ABSENCE OF flight_date
        {flight_date: Date.new(2024, 7, 30), ticket_price: 365, airline: 'egyptair', traveler_id: traveler1.id, trip_type: 'return'}, #ABSENCE OF ticket_no
        {flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", airline: 'egyptair', traveler_id: traveler1.id, trip_type: 'return'}, #ABSENCE OF ticket_price
        {flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, traveler_id: traveler1.id, trip_type: 'return'}, #ABSENCE OF airline
        {flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', trip_type: 'return'}, #ABSENCE OF traveler_id
        {flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', traveler_id: traveler1.id}, #ABSENCE OF trip_type
      ]
    }

  let(:headers) {
      {        
          "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
      }    
  }

  before (:each) do
      Flight.delete_all
  end 
  
  describe 'GET /flights' do

      before do
          FactoryBot.create(:flight, valid_attributes[0])
          FactoryBot.create(:flight, valid_attributes[1])    
      end

      context 'without query parameters' do
          before do
              get '/api/v1/flights', headers: headers  
          end

          it 'returns all flights' do
              expect(JSON.parse(response.body).size).to eq(2)
          end           
          
          it 'returns a 200 Success status' do
              expect(response).to have_http_status(:success)         
          end        
      end

      context 'with query parameters' do
          it 'returns a specific flight depending on query parameters' do
              get '/api/v1/flights',  headers: headers, params: {ticket_no: valid_attributes[0][:ticket_no]}    
              expect(JSON.parse(response.body).size).to eq(1)
              expect(response).to have_http_status(:success)         
              expect(response.body).to include({ id: 1 }.merge(valid_attributes[0]).to_json)
          end     

          it 'does not apply filter on parameters which is not allowed via controller' do
              get '/api/v1/flights',  headers: headers, params: {price: 578}    
              expect(JSON.parse(response.body).size).to eq(2)
              expect(response).to have_http_status(:success)         
          end
      end
      
      context 'missing authorization header ' do
          it 'returns a 401' do
              get '/api/v1/flights', headers: {}  
              expect(response).to have_http_status(:unauthorized)         
          end
      end
  end 

  describe 'GET /flights/:id' do
      let(:flight) {FactoryBot.create(:flight, valid_attributes[0])}
         
      it 'returns a specific flight' do
          get "/api/v1/flights/#{flight.id}", headers: headers
          expect(JSON.parse(response.body).size).to eq(7)
          expect(response).to have_http_status(:success)         
          expect(response.body).to eq({id:1}.merge(valid_attributes[0]).to_json)
      end

      context 'with non existing flight' do
        it 'returns a 404' do
            get "/api/v1/flights/500", headers: headers
            expect(response).to have_http_status(:not_found)         
        end  
      end

      context 'without authorization header' do
        it 'returns a 401' do
            get "/api/v1/flights/#{flight.id}"
            expect(response).to have_http_status(:unauthorized)         
        end
      end
  end
  
  describe 'POST /flights' do

      context 'with valid attributes' do

        before do
            post '/api/v1/flights', 
            params: {flight: valid_attributes[0]}, 
            headers: headers     
        end
  
        it 'creates a new flight' do
            expect(Flight.count).to eq(1)
        end

        it 'returns a 201 Created status' do
            expect(response).to have_http_status(:created)
        end  
        
        it 'returns the created flight attributes in the response' do
            expect(response.body).to include({id:1}.merge(valid_attributes[0]).to_json)
        end

        context 'missing authorization header ' do
            it 'returns a 401' do
                post '/api/v1/flights', params: {flight: valid_attributes[0]}, headers: {}
                expect(response).to have_http_status(:unauthorized)         
            end
        end          
      end

      context 'with invalid attributes' do           
          it 'returns error when flight_date is absent' do
              post '/api/v1/flights', 
              params: {flight: invalid_attributes[0]},
              headers: headers   
              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({"flight_date" => ["can't be blank"]})
          end

          it 'returns error when ticket_no is absent' do
              post '/api/v1/flights', 
              params: {flight: invalid_attributes[1]},
              headers: headers   
              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({"ticket_no" => ["can't be blank"]})
          end
   
          it 'returns error when ticket_price is absent' do
              post '/api/v1/flights', 
              params: {flight: invalid_attributes[2]},
              headers: headers   
              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({"ticket_price" => ["can't be blank"]})
          end

          it 'returns error when airline is absent' do
              post '/api/v1/flights', 
              params: {flight: invalid_attributes[3]},
              headers: headers   
              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({"airline" => ["can't be blank"]})
          end

          it 'returns error when traveler_id is absent' do
              post '/api/v1/flights', 
              params: {flight: invalid_attributes[4]},
              headers: headers   
              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({"traveler" => ["must exist"]})
          end

          it 'returns error when trip_type is absent' do
              post '/api/v1/flights', 
              params: {flight: invalid_attributes[5]},
              headers: headers   
              expect(response).to have_http_status(:unprocessable_entity)
              expect(JSON.parse(response.body)).to eq({"trip_type" => ["can't be blank"]})
          end

      end

      context 'without authorization header' do
        it 'returns a 401' do
            post '/api/v1/flights', 
            params: {flight: valid_attributes[0]}
            expect(response).to have_http_status(:unauthorized)         
        end
      end
  end

  describe 'DELETE /flights/:id' do
      let(:flight) { FactoryBot.create(:flight, valid_attributes[0]) }

      it 'deletes a flight' do
          delete "/api/v1/flights/#{flight.id}", headers: headers      
          expect(Flight.exists?(flight.id)).to be_falsey
          expect(response).to have_http_status(:no_content)
      end

      context 'missing authorization header ' do
          it 'returns a 401' do
              delete "/api/v1/flights/#{flight.id}", headers: {}     
              expect(response).to have_http_status(:unauthorized)         
          end
      end
  end

  describe 'PUT /flights/:id' do
      let(:flight) { FactoryBot.create(:flight, valid_attributes[0]) }

      context 'with valid attributes' do
        before do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {ticket_price: 300 }},
            headers: headers
        end

        it 'update a flight' do 
            expect(response).to have_http_status(:ok)
        end  

        it 'returns the new updated flight' do
            expect(response.body).to include_json(ticket_price: 300)
        end  
      end

      context 'with invalid attributes' do
        it 'returns error when flight_date is absent' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {flight_date: " "}},
            headers: headers   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"flight_date" => ["can't be blank"]})
        end

        it 'returns error when ticket_no is absent' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {ticket_no: " "}},
            headers: headers   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"ticket_no" => ["can't be blank"]})
        end

        it 'returns error when ticket_price is absent' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {ticket_price: " "}},
            headers: headers   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"ticket_price" => ["can't be blank"]})
        end

        it 'returns error when airline is absent' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {airline: " "}},
            headers: headers   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"airline" => ["can't be blank"]})
        end

        it 'returns error when traveler_id is absent' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {traveler_id: " "}},
            headers: headers   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"traveler" => ["must exist"]})
        end

        it 'returns error when trip_type is absent' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {trip_type: " "}},
            headers: headers   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"trip_type" => ["can't be blank"]})
        end

        it 'returns the same flight when provided with non-permitted attrs' do
            put "/api/v1/flights/#{flight.id}", 
            params: {flight: {ticket_avg: " "}},
            headers: headers   

            expect(response).to have_http_status(:ok)
            expect(response.body).to include(
                flight.attributes.slice('id', 'flight_date', 'ticket_no', 'ticket_price', 'airline', 'traveler_id', 'trip_type').to_json)
        end

      end

      context 'with non existing flight' do
        it 'returns error when flight_id deos not exist' do
            put "/api/v1/flights/500", 
            params: {flight_expense: {flight_id: 200 }},
            headers: headers 
            expect(response).to have_http_status(:not_found)
        end  
      end

      context 'missing authorization header ' do
          it 'returns a 401' do
              put "/api/v1/flights/#{flight.id}", headers: {}     
              expect(response).to have_http_status(:unauthorized)         
          end
      end
  end
end
