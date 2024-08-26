require 'rails_helper'

RSpec.describe "Orders", type: :request do

  let(:super_editor) {FactoryBot.create(:editor, name: "admin", email: "admin@gmail.com", password: '123456', super_editor: true)}
  let(:editor) {FactoryBot.create(:editor, name: "admin2", email: "admin2@gmail.com", password: '123456', super_editor: false)}
  let(:customer) {FactoryBot.create(:customer, name: "ismail", phone: "1010101010", editor_id: editor.id)}

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

  let(:valid_attributes) {[
    {order_date: Date.new(2024, 05, 25), total: 340, customer_id: customer.id},
    {order_date: Date.new(2024, 05, 24), total: 270, customer_id: customer.id},
  ]
  }

  let(:invalid_attributes) {[
    {total: 340, customer_id: customer.id}, #absence of order_date
    {order_date: Date.new(2024, 05, 24),customer_id: customer.id}, #absence of total
    {order_date: Date.new(2024, 05, 24), total: 270}, #absence of customer_id
  ]
  }


  before (:each) do
    Customer.delete_all
    Order.delete_all
  end 


  describe "GET /orders" do
    before do
      FactoryBot.create(:order, valid_attributes[0])
      FactoryBot.create(:order, valid_attributes[1])    
    end

    context 'without query parameters' do
      before do
          get '/api/v1/orders', headers: valid_headers_for_editor  
      end

      it 'returns all orders' do
          expect(JSON.parse(response.body).size).to eq(2)
      end           
      
      it 'returns a 200 Success status' do
          expect(response).to have_http_status(:success)         
      end        
    end

    context 'with query parameters' do
      it 'returns a specific order depending on query parameters' do
          get '/api/v1/orders', headers: valid_headers_for_editor, params: {total: valid_attributes[1][:total]}    
          expect(JSON.parse(response.body).size).to eq(1)
          expect(response).to have_http_status(:success)         
          expect(response.body).to include({id:2}.merge(valid_attributes[1]).to_json)
      end     

      it 'does not apply filter on parameters which is not allowed via controller' do
          get '/api/v1/orders',  headers: valid_headers_for_editor, params: {price: 578}    
          expect(JSON.parse(response.body).size).to eq(2)
          expect(response).to have_http_status(:success)         
      end
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
          get '/api/v1/orders', headers: {}  
          expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe "GET /orders/:id" do
    let(:order) {FactoryBot.create(:order, valid_attributes[0])}

    it 'returns a specific order' do
      get "/api/v1/orders/#{order.id}", headers: valid_headers_for_editor  
      expect(JSON.parse(response.body).size).to eq(4)
      expect(response).to have_http_status(:success)         
      expect(response.body).to eq({id: order.id}.merge(valid_attributes[0]).to_json)
    end

    context 'with non existing order' do
      it 'returns a 404' do
          get "/api/v1/orders/500"  
          expect(response).to have_http_status(:not_found)         
      end  
    end

    context 'missing authorization header ' do
      it 'returns a 404' do
          get '/api/v1/orders/500', headers: {}  
          expect(response).to have_http_status(:not_found)         
      end
    end

  end

  describe 'POST /orders' do

    context 'with valid attributes' do
        before do
          post '/api/v1/orders', 
          params: {order: valid_attributes[0]}, 
          headers: valid_headers_for_editor     
        end

        it 'creates a new order' do
            expect(Order.count).to eq(1)
        end

        it 'returns a 201 Created status' do
            expect(response).to have_http_status(:created)
        end  
        
        it 'returns the created order attributes in the response' do
            expect(response.body).to eq({id: 1}.merge(valid_attributes[0]).to_json)
        end    
    end

    context 'with invalid attributes' do 
 
        it 'returns error when order_date is absent' do
            post '/api/v1/orders', 
            params: {order: invalid_attributes[0]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"order_date" => ["can't be blank"]})
        end

        it 'returns error when total is absent' do
            post '/api/v1/orders', 
            params: {order: invalid_attributes[1]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"total" => ["can't be blank"]})
        end

        it 'returns error when customer_id is absent' do
            post '/api/v1/orders', 
            params: {order: invalid_attributes[2]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"customer" => ["must exist"]})
        end
    end

    context 'without authorization header' do
        it 'returns a 401' do
            post '/api/v1/orders', 
            params: {order: valid_attributes[0]}

            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end

  describe 'DELETE /orders/:id' do
    let(:order) { FactoryBot.create(:order, valid_attributes[0]) }

    it 'deletes a order' do
        delete "/api/v1/orders/#{order.id}", headers: valid_headers_for_editor      
        expect(Order.exists?(order.id)).to be_falsey
        expect(response).to have_http_status(:no_content)
    end
    
    context 'with non-existing order' do
        it 'returns a 404' do
            delete "/api/v1/orders/500", headers: valid_headers_for_editor      
            expect(response).to have_http_status(:not_found)         
        end  
    end

    context 'without authorization header ' do
        it 'returns a 401' do
            delete "/api/v1/orders/#{order.id}", headers: {}     
            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end
  
  describe 'PUT /orders/:id' do
    let(:order) { FactoryBot.create(:order, valid_attributes[0]) }

    it 'update a order' do 
        put "/api/v1/orders/#{order.id}", 
        params: {order: {total: 200}},
        headers: valid_headers_for_editor

        expect(Order.exists?(order.id)).to be_truthy
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json(total: 200)
    end  

    context 'with non-existing order' do
        it 'returns a 404' do
            put "/api/v1/orders/500", 
            params: {order: {total: 105}},
            headers: valid_headers_for_editor

            expect(response).to have_http_status(:not_found)         
        end  
    end

    context 'missing authorization header ' do
        it 'returns a 401' do
            put "/api/v1/orders/#{order.id}", headers: {}     
            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end
end
