require 'rails_helper'


describe 'Traveler API', type: :request do

    let(:super_editor) {FactoryBot.create(:editor, name: "ismail", email: "ismailkamal@gmail.com", password: '123456', super_editor: true)}
    let(:editor) {FactoryBot.create(:editor, name: "rewan", email: "rewan@gmail.com", password: '123456', super_editor: false)}

     let (:valid_attributes) {
        [
            {name: 'khaled swailem', phone: '1099929132'},
            {name: 'hoda baza', phone: '1050542911'}
        ]
    }

    let(:invalid_attributes) {
        [
        {phone: "5405646577", editor_id: super_editor.id}, # absence of name attr
        {name: 'ahmed', editor_id: super_editor.id}, # absence of phone attr
        {name: 'ahmed', phone: "55316125613", editor_id: super_editor.id}, # phone is more than 10 digit string
        {name: 'ahmed', phone: "d4d5d1d5d6", editor_id: super_editor.id}, # phone contains chars
        ]  
    }
    
    let(:valid_headers_for_super_editor) {
        {
            "Authorization" => "Bearer #{AuthenticationTokenService.encode(super_editor.id)}"
        }
    }

    let(:valid_headers_for_editor) {
        {
            "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
        }
    }

    before (:each) do
        Traveler.delete_all
    end 


    describe 'GET /travelers' do

        before do
            valid_attributes.map { |attr| 
              Traveler.create!(attr.merge(editor_id: super_editor.id))
            }
        end

        context 'without query parametes' do
            before do
                get '/api/v1/travelers', headers: valid_headers_for_super_editor  
            end

            it 'returns all travelers' do
                expect(JSON.parse(response.body).size).to eq(2)
            end           
            
            it 'returns a 200 Success status' do
                expect(response).to have_http_status(:success)         
            end               
        end  

        context 'with query parameters' do
            it 'returns a specific traveler depending on query parameters' do
                get '/api/v1/travelers',  headers: valid_headers_for_super_editor, params: {name: "khaled swailem"}    
                expect(JSON.parse(response.body).size).to eq(1)
                expect(response).to have_http_status(:success)         
                expect(response.body).to include({id:1, name: "khaled swailem", phone: "1099929132", "editor_id": super_editor.id}.to_json)
              end      
        
              it 'does not apply filter on parameters which is not allowed via controller' do
                get '/api/v1/travelers',  headers: valid_headers_for_super_editor, params: {age: 18}    
                expect(JSON.parse(response.body).size).to eq(2)
                expect(response).to have_http_status(:success)         
              end                      
        end  

        context 'missing authorization header' do
            it 'returns a 401' do
                get '/api/v1/travelers', headers: {}
                expect(response).to have_http_status(:unauthorized)         
              end                      
        end  
    end
      
    describe 'GET /travelers/:id' do
        let(:traveler) { FactoryBot.create(:traveler, valid_attributes[0].merge(editor_id: super_editor.id)) }
    
        it 'returns a specific traveler' do
    
            get "/api/v1/travelers/#{traveler.id}", headers: valid_headers_for_super_editor  
            expect(JSON.parse(response.body).size).to eq(4)
            expect(response).to have_http_status(:success)    
            expect(response.body).to eq({id: traveler.id, name: valid_attributes[0][:name], phone: valid_attributes[0][:phone], "editor_id": super_editor.id}.to_json)
        end
    
        context 'missing authorization header ' do
          it 'returns a 401' do
            get "/api/v1/travelers/#{traveler.id}", headers: {}
            expect(response).to have_http_status(:unauthorized)         
          end
        end

        context 'with non-existing traveler_id' do
          it 'returns a 401' do
              get '/api/v1/travelers/200', headers: valid_headers_for_super_editor
              expect(response).to have_http_status(:not_found)         
            end                      
        end 
    end
    
    describe 'POST /travelers' do
      context 'with valid attributes' do
  
        before do
            post '/api/v1/travelers', 
              params: {traveler: valid_attributes[0]},
              headers: valid_headers_for_super_editor    
        end
  
        it 'creates a new traveler' do
            expect(Traveler.count).to eq(1)
        end
  
        it 'returns a 201 Created status' do
            expect(response).to have_http_status(:created)
        end  
        
        it 'returns the created traveler attributes in the response' do
            expect(response.body).to include_json({name: valid_attributes[0][:name], phone: valid_attributes[0][:phone]})
        end
      end
  
      context 'with invalid attributes' do 
        
        it 'returns error when name is absent' do
            post '/api/v1/travelers', 
            params: {traveler: invalid_attributes[0]},
            headers: valid_headers_for_super_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"name" => ["can't be blank"]})
        end
  
        it 'returns error when phone is absent' do
            post '/api/v1/travelers', 
            params: {traveler: invalid_attributes[1]},
            headers: valid_headers_for_super_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"phone" => ["can't be blank", "must be a valid 10-digit phone number"]})
        end
  
        it 'returns error phone is more than 10 digit' do
            post '/api/v1/travelers', 
            params: {traveler: invalid_attributes[2]},
            headers: valid_headers_for_super_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"phone" => ["must be a valid 10-digit phone number"]})
        end
  
        it 'returns error phone attribute contains chars' do
            post '/api/v1/travelers', 
            params: {traveler: invalid_attributes[3]},
            headers: valid_headers_for_super_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"phone" => ["must be a valid 10-digit phone number"]})
        end
  
        it 'returns error when phone is duplicate' do 
          FactoryBot.create(:traveler, valid_attributes[1].merge(editor_id: super_editor.id))
  
          post '/api/v1/travelers', 
          params: {traveler: valid_attributes[1]},
          headers: valid_headers_for_super_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["has already been taken"]})
        end  
      end
  
      context 'missing authorization header ' do
        it 'returns a 401' do
          post '/api/v1/travelers', 
            params: {traveler: valid_attributes[0]},
            headers: {}   
          expect(response).to have_http_status(:unauthorized)         
        end
      end

      context 'with editor headers' do
        it 'returns 401 error' do
          post '/api/v1/travelers', 
          params: {traveler: valid_attributes[0]},
          headers: valid_headers_for_editor 
          expect(response).to have_http_status(:unauthorized)  
          expect(response.body).to eq("unauthorized request: this action is allowed only for admins")
        end
      end
    end
  
    describe 'DELETE /travelers/:id' do
      let(:traveler) {FactoryBot.create(:traveler,  valid_attributes[0].merge(editor_id: super_editor.id))}
  
      it 'deletes a traveler' do
          delete "/api/v1/travelers/#{traveler.id}", headers: valid_headers_for_super_editor     
  
          expect(Traveler.exists?(traveler.id)).to be_falsey
          expect(response).to have_http_status(:no_content)
      end
  
      context 'missing authorization header ' do
        it 'returns a 401' do
          delete "/api/v1/travelers/#{traveler.id}", headers: {}   
          expect(response).to have_http_status(:unauthorized)         
        end
      end

      context 'with non-existing traveler_id' do
        it 'returns a 404' do
            delete '/api/v1/travelers/200', headers: valid_headers_for_super_editor
            expect(response).to have_http_status(:not_found)         
          end                      
      end 

      context 'with editor headers' do
        it 'returns 401 error' do
          delete "/api/v1/travelers/#{traveler.id}", 
          params: {traveler: valid_attributes[0]},
          headers: valid_headers_for_editor 
          expect(response).to have_http_status(:unauthorized)  
          expect(response.body).to eq("unauthorized request: this action is allowed only for admins")
        end
      end
    end
    
    describe 'PUT /travelers/:id' do
      let(:traveler) {FactoryBot.create(:traveler,  valid_attributes[0].merge(editor_id: super_editor.id))}
  
      context 'with valid attributes' do
        it 'update a traveler' do 
          put "/api/v1/travelers/#{traveler.id}", 
            params: {traveler: {name: 'mohamed'}},
            headers: valid_headers_for_super_editor
  
          expect(response).to have_http_status(:ok)
          expect(response.body).to include_json(name: 'mohamed')
        end  
      end
  
      context 'with invalid attributes' do
        it 'returns error when name is absence' do 
          put "/api/v1/travelers/#{traveler.id}", 
            params: {traveler: {name: ' '}},
            headers: valid_headers_for_super_editor
  
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"name" => ["can't be blank"]})
        end  
  
        it 'returns error when phone is absence' do 
          put "/api/v1/travelers/#{traveler.id}", 
            params: {traveler: {phone: ' '}},
            headers: valid_headers_for_super_editor
  
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["can't be blank", "must be a valid 10-digit phone number"]})
        end  
  
        it 'returns error when phone is not 10 digit' do 
          put "/api/v1/travelers/#{traveler.id}", 
            params: {traveler: {phone: '256sasc'}},
            headers: valid_headers_for_super_editor
  
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["must be a valid 10-digit phone number"]})
        end  
  
        it 'returns error when phone is duplicate' do 
          FactoryBot.create(:traveler,  valid_attributes[1].merge(editor_id: super_editor.id))
  
          put "/api/v1/travelers/#{traveler.id}", 
            params: {traveler: {phone: valid_attributes[1][:phone]}},
            headers: valid_headers_for_super_editor
  
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["has already been taken"]})
        end  
      end
  
      context 'missing authorization header ' do
        it 'returns a 401' do
          put "/api/v1/travelers/#{traveler.id}", params: {traveler: {name: 'mohamed'}}, headers: {}
          expect(response).to have_http_status(:unauthorized)         
        end
      end

      context 'with non-existing traveler_id' do
        it 'returns a 404' do
            put '/api/v1/travelers/200', headers: valid_headers_for_super_editor
            expect(response).to have_http_status(:not_found)         
          end                      
      end 

      context 'with editor headers' do
        it 'returns 401 error' do
          put "/api/v1/travelers/#{traveler.id}", 
          headers: valid_headers_for_editor 
          expect(response).to have_http_status(:unauthorized)  
          expect(response.body).to eq("unauthorized request: this action is allowed only for admins")
        end
      end

    end
end