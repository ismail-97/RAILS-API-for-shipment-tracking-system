require 'rails_helper'

RSpec.describe 'Contents API', type: :request do
    let(:editor) {FactoryBot.create(:editor, name: "ismail", email: "ismailkamal@gmail.com", password: '123456', super_editor: true)}
    let(:customer) {FactoryBot.create(:customer, name: "ismail", phone: "1010101010", editor_id: editor.id)}
    let(:traveler) {FactoryBot.create(:traveler, name: "khaled swailem", phone: "1099929132", editor_id: editor.id)}
    let (:flight) {FactoryBot.create(:flight, flight_date: Date.new(2024, 7, 30), ticket_no: "077-2445660549", ticket_price: 365, airline: 'egyptair', traveler_id: traveler.id, trip_type: 'return')}

    let (:shipment1) {FactoryBot.create(:shipment, status: 'received', direction: "tr-eg", total: 6500, customer_id: customer.id, editor_id: editor.id, flight_id: flight.id)}
    let (:shipment2) {FactoryBot.create(:shipment, status: 'received', direction: "tr-eg", total: 9540, customer_id: customer.id, editor_id: editor.id, flight_id: flight.id)}

    let(:valid_attributes) {[
        {content_type: 'shoes', weight: 1500, items_number: 50, kg_price: 500, shipment_id: shipment1.id},
        {content_type: 'food_products', weight: 700, items_number: 10, kg_price: 400, shipment_id: shipment1.id},
        {content_type: 'clothes', weight: 700, items_number: 35, kg_price: 450, shipment_id: shipment2.id},
      ]
    }

    let(:invalid_attributes) {[
      {weight: 1500, items_number: 50, kg_price: 500, shipment_id: shipment1.id}, # non-existing content_type
      {content_type: 'shoes', items_number: 50, kg_price: 500, shipment_id: shipment1.id}, # non-existing weight
      {content_type: 'shoes', weight: 1500, kg_price: 500, shipment_id: shipment1.id}, # non-existing items_number
      {content_type: 'shoes', weight: 1500, items_number: 50, shipment_id: shipment1.id}, # non-existing kg_price
      {content_type: 'shoes', weight: 1500, items_number: 50, kg_price: 500}, # non-existing shipment_id
      {content_type: 'washing machine', weight: 700, items_number: 35, kg_price: 450, shipment_id: shipment2.id}, # invalid content_type
      {content_type: 'shoes', weight: 700, items_number: 35, kg_price: 450, shipment_id: 500}, # invalid shipment_id
      {content_type: 'shoes', weight: -390, items_number: 35, kg_price: 450, shipment_id: shipment2.id}, # invalid weight
      {content_type: 'shoes', weight: 700, items_number: "string", kg_price: 450, shipment_id: shipment2.id}, # invalid items_number
      ]
    }

    let(:headers) {
        {        
            "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
        }    
    }

    before (:each) do
        Content.delete_all
    end 

    describe 'GET shipments/:shipment_id/contents' do

        before do  
            valid_attributes.map { |attributes| 
                FactoryBot.create(:content, attributes)
            }
        end
        
        context 'without query parameters' do
            before do
                get "/api/v1/shipments/#{shipment1.id}/contents", headers: headers  
            end
  
            it 'returns all shipment contents' do
                expect(JSON.parse(response.body).size).to eq(2)
            end           
            
            it 'returns a 200 Success status' do
                expect(response).to have_http_status(:success)         
            end        
        end   

        context 'with query parameters' do
            it 'returns specific shipment contents depending on query parameters' do
              get "/api/v1/shipments/#{shipment1.id}/contents", 
              headers: headers, 
              params: {content_type: valid_attributes[0][:content_type]}    

              expect(JSON.parse(response.body).size).to eq(1)
              expect(response).to have_http_status(:success)         
              expect(response.body).to include({ id: 1 }.merge(valid_attributes[0]).to_json)
            end     
  
            it 'does not apply filter on parameters which is not allowed via controller' do
              get "/api/v1/shipments/#{shipment1.id}/contents", 
              headers: headers, 
              params: {name: "ismail"}    
              expect(JSON.parse(response.body).size).to eq(2)
              expect(response).to have_http_status(:success)         
            end
        end
        
        context 'without authorization header ' do
          it 'returns a 401' do
            get "/api/v1/shipments/#{shipment1.id}/contents", headers: {}
            expect(response).to have_http_status(:unauthorized)         
          end
        end

        context 'with non-existing shipment ' do
            it 'returns a 404' do
              get "/api/v1/shipments/500/contents"
              expect(response).to have_http_status(:not_found)         
            end
        end
    end

    describe 'GET shipments/:shipment_id/contents/:content_id' do
        let(:content) {FactoryBot.create(:content, valid_attributes[0])} 

        context 'with existing shipment & shipment content' do
            before do
                get "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}", headers: headers
            end

            it 'returns a specific flight expense' do
              expect(JSON.parse(response.body).size).to eq(6)
              expect(response.body).to eq({id:content.id}.merge(valid_attributes[0]).to_json)
            end   
            
            it 'returns a 200 Success status' do
                expect(response).to have_http_status(:success)         
            end   
        end

        context 'with non existing shipment' do
            it 'returns a 404' do
                get "/api/v1/shipments/500/contents/#{content.id}", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'with non existing content' do
            it 'returns a 404' do
                get "/api/v1/shipments/#{shipment1.id}/contents/500", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header ' do
            it 'returns a 401' do
                get "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}", headers: {}
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end

    describe 'POST shipments/:shipment_id/contents' do
        context 'with valid attributes' do
            before do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: valid_attributes[0]}, 
                headers: headers     
            end
      
            it 'creates a new content' do
                expect(Content.count).to eq(1)
            end
    
            it 'returns a 201 Created status' do
                expect(response).to have_http_status(:created)
            end  
            
            it 'returns the created content attributes in the response' do
                expect(response.body).to include({id:1}.merge(valid_attributes[0]).to_json)
            end
        end

        context 'with invalid attributes' do
            it 'returns error when content_type does not exist' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[0]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"content_type" => ["is not included in the list"]})
            end
            it 'returns error when weight does not exist' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[1]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"weight" => ["can't be blank", "is not a number"]})
            end
            it 'returns error when items_number does not exist' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[2]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"items_number" => ["can't be blank", "is not a number"]})
            end
            it 'returns error when kg_price does not exist' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[3]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"kg_price" => ["can't be blank", "is not a number"]})
            end
            it 'returns error when shipment_id does not exist' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[4]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"shipment" => ["must exist"]})
            end
            it 'returns error when content_type is invalid' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                    params: {content: invalid_attributes[5]},
                    headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"content_type" => ["is not included in the list"]})
            end
            it 'returns error when shipment_id is invalid' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[6]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"shipment" => ["must exist"]})
            end
            it 'returns error when weight is less than 0' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[7]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"weight" => ["must be greater than 0"]})
            end
            it 'returns error when items_number is not an number' do
                post "/api/v1/shipments/#{shipment1.id}/contents", 
                params: {content: invalid_attributes[8]},
                headers: headers   
                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"items_number" => ["is not a number"],})
            end
           
        end

        context 'with non existing flight_id' do
            it 'returns a 404' do
                post "/api/v1/shipments/500/contents", headers: headers, params: valid_attributes[0]
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header' do
            it 'returns a 401' do
                post "/api/v1/shipments/#{shipment1.id}/contents", headers: {}, params: valid_attributes[0]
                expect(response).to have_http_status(:unauthorized)         
            end
        end
    end

    describe 'DELETE shipments/:shipment_id/contents/:content_id' do
        let(:content) {FactoryBot.create(:content, valid_attributes[0])} 
      
        it 'deletes a content' do
            delete "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}", headers: headers
            expect(Content.exists?(content.id)).to be_falsey
            expect(response).to have_http_status(:no_content)
        end
  
        context 'missing authorization header ' do
            it 'returns a 401' do
                delete "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}", headers: {}
                expect(response).to have_http_status(:unauthorized)         
            end
        end

        context 'with non-existing shipment id' do
            it 'returns a 404' do
              delete "/api/v1/shipments/500/contents/#{content.id}", headers: headers
              expect(response).to have_http_status(:not_found)  
            end
          end

        context 'with non-existing content id' do
        it 'returns a 404' do
            delete "/api/v1/shipments/#{shipment1.id}/contents/500", headers: headers
            expect(response).to have_http_status(:not_found)  
        end
        end
    end

    describe 'PUT shipments/:shipment_id/contents/:content_id' do

        let(:content) {FactoryBot.create(:content, valid_attributes[0])} 

        context 'with valid attributes' do 
            before do
                put "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}",
                params: {content: { content_type: "cosmetics" }},
                headers: headers               
            end

            it 'updates a content' do
                expect(response).to have_http_status(:ok)
            end

            it 'returns the new updated content' do
                expect(response.body).to include_json(content_type: "cosmetics")             
            end      
        end

        context 'with invalid attributes' do 
            it 'returns error when content_type does not exist' do
                put "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}",
                params: {content: {content_type: "washing machine" }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"content_type" => ["is not included in the list"]})
            end

            it 'returns error when weight does not exist' do
                put "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}",
                params: {content: {weight: " " }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"weight" => ["can't be blank", "is not a number"]})
            end

            it 'returns error when items_number does not exist' do
                put "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}",
                params: {content: {items_number: " " }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"items_number" => ["can't be blank", "is not a number"]})
            end

            it 'returns error when kg_price does not exist' do
                put "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}",
                params: {content: {kg_price: " " }},
                headers: headers 

                expect(response).to have_http_status(:unprocessable_entity)
                expect(JSON.parse(response.body)).to eq({"kg_price" => ["can't be blank", "is not a number"]})
            end
 
        end

        context 'with non existing flight' do
            it 'returns a 404' do
                put "/api/v1/shipments/500/contents/#{content.id}", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'with non existing flight expenses' do
            it 'returns a 404' do
                put "/api/v1/shipments/#{shipment1.id}/contents/500", headers: headers
                expect(response).to have_http_status(:not_found)         
            end  
        end

        context 'without authorization header ' do
            it 'returns a 401' do
                put "/api/v1/shipments/#{shipment1.id}/contents/#{content.id}", headers: {}
                expect(response).to have_http_status(:unauthorized)         
            end
        end     
    end    
end