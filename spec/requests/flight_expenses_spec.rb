require 'rails_helper'

RSpec.describe 'Flight Expenses API', type: :request do
    let(:editor) {FactoryBot.create(:editor, name: "ismail", email: "ismailkamal@gmail.com", password: '123456', super_editor: true)}
    let(:traveler) {FactoryBot.create(:traveler, name: "khaled swailem", phone: "1099929132", editor_id: editor.id)}
    let (:flight1) {FactoryBot.create(:flight, flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', traveler_id: traveler.id, trip_type: 'return')}
    let (:flight2) {FactoryBot.create(:flight, flight_date: Date.new(2024, 7, 05), ticket_no: "077-2445660523", ticket_price: 365, airline: 'egyptair', traveler_id: traveler.id,  trip_type: 'one-way')}

    let(:valid_attributes) {[
        {expense_type: "baggage", amount: 1500, flight_id: flight1.id, direction: "tr"},
        {expense_type: "shipping to Alexandria", amount: 700, flight_id: flight1.id, direction: "tr"},
        {expense_type: "shipping to Alexandria", amount: 700, flight_id: flight2.id, direction: "eg"},
      ]
    }

    let(:invalid_attributes) {[
        {amount: 1500, flight_id: flight1.id, direction: "eg"}, # non-existing expense_type
        {expense_type: "shipping to Alexandria", flight_id: flight1.id, direction: "eg"}, # non-existing amount
        {expense_type: "shipping to Alexandria", amount: 700, direction: "eg"}, # non-existing flight_id
        {expense_type: "shipping to Alexandria",amount: 1500, flight_id: flight1.id}, # non-existing direction
      ]
    }

    let(:headers) {
        {        
            "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
        }    
    }

    before (:each) do
        FlightExpense.delete_all
    end 

    describe 'GET flights/:flight_id/flight_expenses' do

        before do  
            valid_attributes.map { |attributes| 
                FactoryBot.create(:flight_expense, attributes)
            }
        end
        
        context 'without query parameters' do
            before do
                get "/api/v1/flights/#{flight1.id}/flight_expenses", headers: headers  
            end
  
            it 'returns all flight expenses' do
                expect(JSON.parse(response.body).size).to eq(2)
            end           
            
            it 'returns a 200 Success status' do
                expect(response).to have_http_status(:success)         
            end        
        end   

        context 'with query parameters' do
            it 'returns specific flight expenses depending on query parameters' do
                get "/api/v1/flights/#{flight1.id}/flight_expenses",  headers: headers, params: {expense_type: valid_attributes[0][:expense_type]}    
                expect(JSON.parse(response.body).size).to eq(1)
                expect(response).to have_http_status(:success)         
                expect(response.body).to include({ id: 1 }.merge(valid_attributes[0]).to_json)
            end     
  
            it 'does not apply filter on parameters which is not allowed via controller' do
                get "/api/v1/flights/#{flight1.id}/flight_expenses",  headers: headers, params: {price: 578}    
                expect(JSON.parse(response.body).size).to eq(2)
                expect(response).to have_http_status(:success)         
            end
        end
        
        context 'without authorization header ' do
            it 'returns a 401' do
                get "/api/v1/flights/#{flight1.id}/flight_expenses"  
                expect(response).to have_http_status(:unauthorized)         
            end
        end

        context 'with non-existing flight ' do
            it 'returns a 404' do
                get '/api/v1/flights/10/flight_expenses'
                expect(response).to have_http_status(:not_found)         
            end
        end
    end

    describe 'GET flights/:flight_id/flight_expenses/:id' do
        let(:flight_expense) {FactoryBot.create(:flight_expense, valid_attributes[0])} 

        context 'with existing flight & flight expense' do

            before do
                get "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}", headers: headers
            end

            it 'returns a specific flight expense' do
              expect(JSON.parse(response.body).size).to eq(5)
              expect(response.body).to eq({id:flight_expense.id}.merge(valid_attributes[0]).to_json)
            end   
            
            it 'returns a 200 Success status' do
                expect(response).to have_http_status(:success)         
            end   
        end

        context 'with non existing flight' do
            it 'returns a 404' do
                get "/api/v1/flights/10/flight_expenses/#{flight_expense.id}", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'with non existing flight expenses' do
            it 'returns a 404' do
                get "/api/v1/flights/#{flight1.id}/flight_expenses/10", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header ' do
            it 'returns a 401' do
                get "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}"
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end

    describe 'POST flights/:flight_id/flight_expenses' do
        context 'with valid attributes' do
            before do
                post "/api/v1/flights/#{flight1.id}/flight_expenses", 
                params: {flight_expense: valid_attributes[0]}, 
                headers: headers     
            end
      
            it 'creates a new flight expense' do
                expect(FlightExpense.count).to eq(1)
            end
    
            it 'returns a 201 Created status' do
                expect(response).to have_http_status(:created)
            end  
            
            it 'returns the created flight expense attributes in the response' do
                expect(response.body).to include({id:1}.merge(valid_attributes[0]).to_json)
            end
        end

        context 'with invalid attributes' do
            it 'returns error when expense_type is absent' do
                post "/api/v1/flights/#{flight1.id}/flight_expenses", 
                params: {flight_expense: invalid_attributes[0]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"expense_type" => ["can't be blank"]})
            end
            
            it 'returns error when amount is absent' do
                post "/api/v1/flights/#{flight1.id}/flight_expenses", 
                params: {flight_expense: invalid_attributes[1]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"amount" => ["can't be blank", "is not a number"]})
            end

            it 'returns error when flight_id is absent' do
                post "/api/v1/flights/#{flight1.id}/flight_expenses", 
                params: {flight_expense: invalid_attributes[2]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"flight" => ["must exist"]})
            end

            it 'returns error when direction is absent' do
                post "/api/v1/flights/#{flight1.id}/flight_expenses", 
                params: {flight_expense: invalid_attributes[3]},
                headers: headers   

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"direction" => ["can't be blank"]})
            end   
        end

        context 'with non existing flight_id' do
            it 'returns a 404' do
                post "/api/v1/flights/10/flight_expenses", headers: headers, params: valid_attributes[0]
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header' do
            it 'returns a 401' do
                post "/api/v1/flights/#{flight1.id}/flight_expenses", params: valid_attributes[0]
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end

    describe 'DELETE flights/:flight_id/flight_expenses/:id' do
        let(:flight_expense) {FactoryBot.create(:flight_expense, valid_attributes[0])} 
      
        it 'deletes a flight' do
            delete "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}", headers: headers
            expect(FlightExpense.exists?(flight_expense.id)).to be_falsey
            expect(response).to have_http_status(:no_content)
        end
  
        context 'missing authorization header ' do
            it 'returns a 401' do
                delete "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}"
                expect(response).to have_http_status(:unauthorized)         
            end
        end

        context 'with non-existing flight id' do
            it 'returns a 404' do
                delete "/api/v1/flights/100/flight_expenses/#{flight_expense.id}", headers: headers
              expect(response).to have_http_status(:not_found)  
            end
          end

        context 'with non-existing flightexpense id' do
        it 'returns a 404' do
            delete "/api/v1/flights/#{flight1.id}/flight_expenses/#100", headers: headers
            expect(response).to have_http_status(:not_found)  
        end
        end
    end

    describe 'PUT flights/:flight_id/flight_expenses/:id' do

        let(:flight_expense) {FactoryBot.create(:flight_expense, valid_attributes[0])} 

        context 'with valid attributes' do 
            before do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}",
                params: {flight_expense: {amount: 200 }},
                headers: headers               
            end

            it 'updates a flight expense' do
                expect(response).to have_http_status(:ok)
            end

            it 'returns the new updated flight expense' do
                expect(response.body).to include_json(amount: 200)             
            end      
        end

        context 'with invalid attributes' do 
            it 'returns error when amount is not integer' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}",
                params: {flight_expense: {amount: "two hundered" }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"amount" => ["is not a number"]})
            end

            it 'returns error when flight_id deos not exist' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}",
                params: {flight_expense: {flight_id: 200 }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"flight" => ["must exist"]})
            end   

            it 'returns error when amount is absent' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}",
                params: {flight_expense: {amount: ' ' }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"amount" => ["can't be blank", "is not a number"]})
            end   

            it 'returns error when expense_type is absent' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}",
                params: {flight_expense: {expense_type: ' ' }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"expense_type" => ["can't be blank"]})
            end   

            it 'returns error when direction is absent' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}",
                params: {flight_expense: {direction: ' ' }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"direction" => ["can't be blank"]})
            end   
        end

        context 'with non existing flight' do
            it 'returns a 404' do
                put "/api/v1/flights/10/flight_expenses/#{flight_expense.id}", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'with non existing flight expenses' do
            it 'returns a 404' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/10", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header ' do
            it 'returns a 401' do
                put "/api/v1/flights/#{flight1.id}/flight_expenses/#{flight_expense.id}"
                expect(response).to have_http_status(:unauthorized)         
            end
        end     
    end    
end