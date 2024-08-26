require 'rails_helper'

describe "Editor API", type: :request do
  let(:super_editor) {FactoryBot.create(:editor, name: "admin", email: "admin@gmail.com", password: '123456', super_editor: true)}
  let(:editor) {FactoryBot.create(:editor, name: "admin2", email: "admin2@gmail.com", password: '123456', super_editor: false)}

  let(:valid_attributes) {
    [
      {name: 'ismail', email: 'ismailkamaleldin@gmail.com', password: '123456', super_editor: false},
      {name: 'ahmed', email: 'arvedsystem@gmail.com', password: '123456', super_editor: false},
    ]
  }
  let(:invalid_attributes) {
    [
      {email: 'arvedsystem@gmail.com', password: '123456', super_editor: false}, # absence of name attr
      {name: 'ahmed', password: '123456', super_editor: false}, # absence of email attr
      {name: 'ahmed', email: 'arvedsystem@gmail.com', super_editor: false}, # absence of password attr
      {name: 'ahmed', email: 'arvedsystem@gmail.com', password: '123456'}, # absence of name super_editor
    ]
  }

  let(:valid_headers_for_admin) {
    {
      "Authorization" => "Bearer #{AuthenticationTokenService.encode(super_editor.id)}"
    }
  }

  let(:valid_headers_for_editor) {
    {
      "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
    }
  }


  before(:each) do
    Editor.delete_all
  end

  describe "GET /editors" do

    before do
      FactoryBot.create(:editor, valid_attributes[0])
      FactoryBot.create(:editor, valid_attributes[1]) 
    end

    context 'without query parameters' do
      before do
          get '/api/v1/editors', headers: valid_headers_for_admin
      end

      it 'returns all editors' do
        expect(JSON.parse(response.body).size).to eq(3)
      end
  
      it 'returns a 200 Success status' do
        expect(response).to have_http_status(:success)
      end
    end
    
    context 'with query parameters' do
      it 'returns a specific editor on query parameters' do
        get '/api/v1/editors',  headers: valid_headers_for_admin, params: {email: 'admin@gmail.com'}    
        expect(JSON.parse(response.body).size).to eq(1)
        expect(response).to have_http_status(:success)         
        expect(response.body).to eq([{id: super_editor.id, name: "admin", email: "admin@gmail.com", super_editor: true}].to_json)
      end

      it 'does not apply filter on parameters which is not allowed via controller' do
          get '/api/v1/editors',  headers: valid_headers_for_admin, params: {age: 22}    
          expect(JSON.parse(response.body).size).to eq(3)
          expect(response).to have_http_status(:success)         
      end
    end

    context 'with admin authorization header ' do
      it 'returns a 401' do
        get '/api/v1/editors', headers: valid_headers_for_editor
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
        get '/api/v1/editors', headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end

  end

  describe "GET /editors/:id" do

    context 'with existing editor_id' do
      before do
        get "/api/v1/editors/#{editor.id}", headers: valid_headers_for_admin
      end

      it 'returns a specific editor' do
        expect(JSON.parse(response.body).size).to eq(4)
        expect(response.body).to eq({id: editor.id, name: 'admin2', email: "admin2@gmail.com", super_editor: false}.to_json)  
      end   
      
      it 'returns a 200 Success status' do
          expect(response).to have_http_status(:success)         
      end   
    end

    context 'with non-existing editor_id' do
      it 'returns a 404' do
        get "/api/v1/editors/10", headers: valid_headers_for_admin
        expect(response).to have_http_status(:not_found)    
      end     
    end  

    context 'without authorization header ' do
      it 'returns a 401' do
        get "/api/v1/editors/#{editor.id}", headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe "POST /editors" do

    context 'with valid attributes' do 
      before do
          post '/api/v1/editors', params: {editor: valid_attributes[0]}, headers: valid_headers_for_admin      
      end

      it 'creates a new editor' do
          expect(Editor.count).to eq(2)
      end

      it 'returns a 201 Created status' do
          expect(response).to have_http_status(:created)
      end  
      
      it 'returns the created editor attributes in the response' do
          expect(response.body).to include_json({name: valid_attributes[0][:name], email: valid_attributes[0][:email]})
      end      
    end

    context 'with invalid attributes' do 
      it 'returns error when name is absent' do
        post '/api/v1/editors', 
        params: {editor: invalid_attributes[0]},
        headers: valid_headers_for_admin   
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"name" => ["can't be blank"]})
      end

      it 'returns error when email is absent' do
          post '/api/v1/editors', 
          params: {editor: invalid_attributes[1]},
          headers: valid_headers_for_admin   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"email" => ["can't be blank", "must be a valid email"]})
      end

      it 'returns error when password is absent' do
          post '/api/v1/editors', 
          params: {editor: invalid_attributes[2]},
          headers: valid_headers_for_admin   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"password" => ["can't be blank", "is too short (minimum is 6 characters)"]})
      end

      it 'returns error when super_editor is absent' do
          post '/api/v1/editors', 
          params: {editor: invalid_attributes[3]},
          headers: valid_headers_for_admin   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"super_editor" => ["is not included in the list"]})
      end

      it 'returns error when email is duplicate' do 
        FactoryBot.create(:editor, valid_attributes[1])

        post '/api/v1/editors', 
        params: {editor: valid_attributes[1]},
        headers: valid_headers_for_admin   
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"email" => ["has already been taken"]})
      end  
    end

    context 'without authorization header ' do
      it 'returns a 401' do
        post '/api/v1/editors', headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'without Admin authorization header ' do
      it 'returns a 401 (Not A Super Admin)' do
        post '/api/v1/editors', headers: valid_headers_for_editor
        expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe 'DELETE /editors/:id' do
    let(:editorToDelete) { FactoryBot.create(:editor, valid_attributes[0]) }

    it 'deletes a editor' do
        delete "/api/v1/editors/#{editorToDelete.id}", headers: valid_headers_for_admin    

        expect(Editor.exists?(editorToDelete.id)).to be_falsey
        expect(response).to have_http_status(:no_content)
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
        delete "/api/v1/editors/#{editor.id}", headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'missing Admin authorization header ' do
      it 'returns a 401 (Not A Super Admin)' do
        delete "/api/v1/editors/#{editor.id}", headers: valid_headers_for_editor
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'with non existing editor_id' do
      it 'returns a 404' do
        delete '/api/v1/editors/500', headers: valid_headers_for_admin   
        expect(response).to have_http_status(:not_found)         
      end  
    end
  end

  describe 'PUT /editors/:id' do

    context 'with valid attributes' do
      it 'update a editor' do 
        patch "/api/v1/editors/#{editor.id}", 
        params: {editor: {name: 'mohamed'}}, 
        headers: valid_headers_for_admin

        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json(name: 'mohamed')
      end  
    end

    context 'with invalid attributes' do
      it 'returns error when name is absence' do 
        patch "/api/v1/editors/#{editor.id}", 
        params: {editor: {name: ' '}}, 
        headers: valid_headers_for_admin

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include_json({"name" => ["can't be blank"]})
      end  

      it 'returns error when email is absence' do 
        put "/api/v1/editors/#{editor.id}", 
          params: {editor: {email: ' '}},
          headers: valid_headers_for_admin

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"email" => ["can't be blank", "must be a valid email"]})
      end  

      it 'returns error when email is duplicate' do 
        FactoryBot.create(:editor, valid_attributes[1])

        put "/api/v1/editors/#{editor.id}", 
          params: {editor: {email: 'admin@gmail.com'}},
          headers: valid_headers_for_admin

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"email" => ["has already been taken"]})
      end  

    end

    context 'missing authorization header ' do
      it 'returns a 401' do
        put "/api/v1/editors/#{editor.id}", headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'missing Admin authorization header ' do
      it 'returns a 401 (Not An Admin)' do
        patch "/api/v1/editors/#{editor.id}", 
          params: {editor: {name: 'mohamed'}}, 
          headers: valid_headers_for_editor
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'with non existing editor' do
      it 'returns a 404' do
        patch "/api/v1/editors/500", 
          params: {editor: {name: 'mohamed'}}, 
          headers: valid_headers_for_editor          
        expect(response).to have_http_status(:not_found)         
      end  
    end

  end
end
