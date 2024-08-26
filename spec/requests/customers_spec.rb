require 'rails_helper'

describe "Customers API" , type: :request do
  let(:editor) {FactoryBot.create(:editor, name: "ismail", email: "ismailkamal@gmail.com", password: '123456', super_editor: true)}

  let(:valid_attributes) {
    [
      {name: 'ismail', phone: "5405646577"},
      {name: 'ahmed', phone: "5316125613"}
    ]
  }

  let(:invalid_attributes) {
    [
      {phone: "5405646577", editor_id: editor.id}, # absence of name attr
      {name: 'ahmed', editor_id: editor.id}, # absence of phone attr
      {name: 'ahmed', phone: "55316125613", editor_id: editor.id}, # phone is more than 10 digit string
      {name: 'ahmed', phone: "d4d5d1d5d6", editor_id: editor.id}, # phone contains chars
    ]  
  }

  let(:header_for_super_editor) {
    {
      "Authorization" => "Bearer #{AuthenticationTokenService.encode(editor.id)}"
    }
  }

  before (:each) do
      Customer.delete_all
  end 

  describe 'GET /customers' do

    before do
      valid_attributes.map { |attr| 
        Customer.create!(attr.merge(editor_id: editor.id))
      }
    end

    context 'without query parametes' do

      before do
        get '/api/v1/customers',  headers: header_for_super_editor    
      end

      it 'returns all customers' do
          expect(JSON.parse(response.body).size).to eq(2)
      end           
      
      it 'returns a 200 Success status' do
          expect(response).to have_http_status(:success)         
      end
    end

    context 'with query parameters' do
      it 'returns a specific customer depending on query parameters' do
        get '/api/v1/customers', headers: header_for_super_editor, params: {name: 'ismail'}    
        expect(JSON.parse(response.body).size).to eq(1)
        expect(response).to have_http_status(:success)         
        expect(response.body).to include({id:2, name: "ismail", phone: "5405646577", "editor_id": editor.id}.to_json)
      end      

      it 'does not apply filter on parameters which is not allowed via controller' do
        get '/api/v1/customers',  headers: header_for_super_editor, params: {age: 18}    
        expect(JSON.parse(response.body).size).to eq(2)
        expect(response).to have_http_status(:success)         
      end
    end

    context 'without authorization header ' do
      it 'returns a 401' do
        get '/api/v1/customers', headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end
    
  end 

  describe 'GET /customers/:id' do
    let(:customer) { FactoryBot.create(:customer, valid_attributes[0].merge(editor_id: editor.id)) }

    context 'with existing customer id' do
      before do
        get "/api/v1/customers/#{customer.id}", headers: header_for_super_editor  
      end

      it 'returns a specific customer' do
        expect(JSON.parse(response.body).size).to eq(4)
        expect(response.body).to eq({id: customer.id, name: 'ismail', phone: "5405646577", "editor_id": editor.id}.to_json)
      end

      it 'returns a 200 Success status' do
        expect(response).to have_http_status(:success)         
      end   
    end

    context 'with non-existing customer id' do
      it 'returns a 404' do
        get "/api/v1/customers/500", headers: header_for_super_editor  
        expect(response).to have_http_status(:not_found)  
      end
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
        get "/api/v1/customers/#{customer.id}", headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe 'POST /customers' do
    context 'with valid attributes' do

      before do
          post '/api/v1/customers', 
            params: {customer: valid_attributes[0]},
            headers: header_for_super_editor    
      end

      it 'creates a new customer' do
          expect(Customer.count).to eq(1)
      end

      it 'returns a 201 Created status' do
          expect(response).to have_http_status(:created)
      end  
      
      it 'returns the created customer attributes in the response' do
          expect(response.body).to include_json({name: valid_attributes[0][:name], phone: valid_attributes[0][:phone]})
      end
    end

    context 'with invalid attributes' do 
      
      it 'returns error when name is absent' do
          post '/api/v1/customers', 
          params: {customer: invalid_attributes[0]},
          headers: header_for_super_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"name" => ["can't be blank"]})
      end

      it 'returns error when phone is absent' do
          post '/api/v1/customers', 
          params: {customer: invalid_attributes[1]},
          headers: header_for_super_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["can't be blank", "must be a valid 10-digit phone number"]})
      end

      it 'returns error phone is more than 10 digit' do
          post '/api/v1/customers', 
          params: {customer: invalid_attributes[2]},
          headers: header_for_super_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["must be a valid 10-digit phone number"]})
      end

      it 'returns error phone attribute contains chars' do
          post '/api/v1/customers', 
          params: {customer: invalid_attributes[3]},
          headers: header_for_super_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"phone" => ["must be a valid 10-digit phone number"]})
      end

      it 'returns error when phone is duplicate' do 
        FactoryBot.create(:customer, valid_attributes[1].merge(editor_id: editor.id))

        post '/api/v1/customers', 
        params: {customer: valid_attributes[1]},
        headers: header_for_super_editor   
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"phone" => ["has already been taken"]})
      end  
    end

    context 'without authorization header ' do
      it 'returns a 401' do
        post '/api/v1/customers', 
          params: {customer: valid_attributes[0]},
          headers: {}   
        expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe 'DELETE /customers/:id' do
    let(:customer) {FactoryBot.create(:customer,  valid_attributes[0].merge(editor_id: editor.id))}

    it 'deletes a customer' do
        delete "/api/v1/customers/#{customer.id}", headers: header_for_super_editor     

        expect(Customer.exists?(customer.id)).to be_falsey
        expect(response).to have_http_status(:no_content)
    end


    context 'missing authorization header ' do
      it 'returns a 401' do
        delete "/api/v1/customers/#{customer.id}", headers: {}   
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'with non-existing customer id' do
      it 'returns a 404' do
        delete "/api/v1/customers/500", headers: header_for_super_editor  
        expect(response).to have_http_status(:not_found)  
      end
    end
  end

  describe 'PUT /customers/:id' do
    let(:customer) {FactoryBot.create(:customer,  valid_attributes[0].merge(editor_id: editor.id))}

    context 'with valid attributes' do
      it 'update a customer' do 
        put "/api/v1/customers/#{customer.id}", 
          params: {customer: {name: 'mohamed'}},
          headers: header_for_super_editor

        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json(name: 'mohamed')
      end  
    end

    context 'with invalid attributes' do
      it 'returns error when name is absence' do 
        put "/api/v1/customers/#{customer.id}", 
          params: {customer: {name: ' '}},
          headers: header_for_super_editor

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"name" => ["can't be blank"]})
      end  

      it 'returns error when phone is absence' do 
        put "/api/v1/customers/#{customer.id}", 
          params: {customer: {phone: ' '}},
          headers: header_for_super_editor

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"phone" => ["can't be blank", "must be a valid 10-digit phone number"]})
      end  

      it 'returns error when phone is not 10 digit' do 
        put "/api/v1/customers/#{customer.id}", 
          params: {customer: {phone: '256sasc'}},
          headers: header_for_super_editor

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"phone" => ["must be a valid 10-digit phone number"]})
      end  

      it 'returns error when phone is duplicate' do 
        FactoryBot.create(:customer,  valid_attributes[1].merge(editor_id: editor.id))

        put "/api/v1/customers/#{customer.id}", 
          params: {customer: {phone: '5316125613'}},
          headers: header_for_super_editor

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({"phone" => ["has already been taken"]})
      end  
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
        put "/api/v1/customers/#{customer.id}", params: {customer: {name: 'mohamed'}}, headers: {}
        expect(response).to have_http_status(:unauthorized)         
      end
    end

    context 'with non-existing customer id' do
      it 'returns a 404' do
        put "/api/v1/customers/500", params: {customer: {name: 'mohamed'}}, headers: header_for_super_editor  
        expect(response).to have_http_status(:not_found)  
      end
    end
  end
end
