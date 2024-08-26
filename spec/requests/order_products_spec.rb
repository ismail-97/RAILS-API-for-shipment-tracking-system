require 'rails_helper'

RSpec.describe "Order Products API", type: :request do

  let(:super_editor) {FactoryBot.create(:editor, name: "admin", email: "admin@gmail.com", password: '123456', super_editor: true)}
  let(:editor) {FactoryBot.create(:editor, name: "admin2", email: "admin2@gmail.com", password: '123456', super_editor: false)}
  let(:customer) {FactoryBot.create(:customer, name: "ismail", phone: "1010101010", editor_id: editor.id)}
  let(:order) {FactoryBot.create(:order, order_date: Date.new(2024, 05, 25), total: 340, customer_id: customer.id)}
  let(:product_1) {FactoryBot.create(:product, product_type: "turkish cheese", stock: 10.0, price: 200.0)}
  let(:product_2) {FactoryBot.create(:product, product_type: "sunflower", stock: 15.0, price: 300.0)}

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
    {quantity: 2.0, price: product_1.price.to_f, order_id: order.id, product_id: product_1.id},
    {quantity: 5.0, price: product_1.price.to_f, order_id: order.id, product_id: product_1.id},
  ]
  }

  let(:invalid_attributes) {[
    {price: product_1.price, order_id: order.id, product_id: product_1.id}, #quantity deosn't exit
    {quantity: 2.0, order_id: order.id, product_id: product_1.id}, #price deosn't exit
    {quantity: 2.0, price: product_1.price, product_id: product_1.id}, #order_id deosn't exit
    {quantity: 2.0, price: product_1.price, order_id: order.id}, #product_id deosn't exit
    {quantity: 11.0, price: product_1.price, order_id: order.id, product_id: product_1.id}, #quantity exceeds product_1's stock
    {quantity: 0.0, price: product_2.price, order_id: order.id, product_id: product_2.id}, #quantity must be greater than 0
  ]
  }


  before (:each) do
    OrderProduct.delete_all
  end 


  describe "GET /order_products" do
    before do
      FactoryBot.create(:order_product, valid_attributes[0])
      FactoryBot.create(:order_product, valid_attributes[1])    
    end

    context 'without query parameters' do
      before do
          get '/api/v1/order_products', headers: valid_headers_for_editor  
      end

      it 'returns all order products' do
          expect(JSON.parse(response.body).size).to eq(2)
      end           
      
      it 'returns a 200 Success status' do
          expect(response).to have_http_status(:success)         
      end        
    end

    context 'with query parameters' do
      it 'returns a specific order product depending on query parameters' do
          get '/api/v1/order_products', headers: valid_headers_for_editor, params: {quantity: valid_attributes[1][:quantity]}    
          expect(JSON.parse(response.body).size).to eq(1)
          expect(response).to have_http_status(:success)         
          expect(response.body).to include({id:2}.merge(valid_attributes[1]).to_json)
      end     

      it 'does not apply filter on parameters which is not allowed via controller' do
          get '/api/v1/order_products',  headers: valid_headers_for_editor, params: {total: 578}    
          expect(JSON.parse(response.body).size).to eq(2)
          expect(response).to have_http_status(:success)         
      end
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
          get '/api/v1/order_products', headers: {}  
          expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe "GET /order_products/:id" do
    let(:order_product) {FactoryBot.create(:order_product, valid_attributes[0])}

    it 'returns a specific order_product' do
      get "/api/v1/order_products/#{order_product.id}", headers: valid_headers_for_editor  
      expect(JSON.parse(response.body).size).to eq(5)
      expect(response).to have_http_status(:success)      
      expect(response.body).to eq({id: order_product.id}.merge(valid_attributes[0]).to_json)
    end

    context 'with non existing order product' do
      it 'returns a 404' do
          get "/api/v1/order_products/500", headers: valid_headers_for_editor
          expect(response).to have_http_status(:not_found)         
      end  
    end

    context 'missing authorization header' do
      it 'returns a 401' do
        get "/api/v1/order_products/#{order_product.id}", headers: {}  
        expect(response).to have_http_status(:unauthorized)         
      end
    end

  end

  describe 'POST /order_products' do

    context 'with valid attributes' do
        before do
          post '/api/v1/order_products', 
          params: {order_product: valid_attributes[0]}, 
          headers: valid_headers_for_editor     
        end

        it 'creates a new order product' do
            expect(OrderProduct.count).to eq(1)
        end

        it 'returns a 201 Created status' do
            expect(response).to have_http_status(:created)
        end  
        
        it 'returns the created order product attributes in the response' do
            expect(response.body).to eq({id: 1}.merge(valid_attributes[0]).to_json)
        end    
    end

    context 'with invalid attributes' do 
 
        it 'returns error when quantity is absent' do
            post '/api/v1/order_products', 
            params: {order_product: invalid_attributes[0]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"quantity" => ["can't be blank", "is not a number"]})
        end

        it 'returns error when price is absent' do
            post '/api/v1/order_products', 
            params: {order_product: invalid_attributes[1]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"price" => ["can't be blank", "is not a number"]})
        end

        it 'returns error when order_id is absent' do
            post '/api/v1/order_products', 
            params: {order_product: invalid_attributes[2]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"order" => ["must exist"]})
        end

        it 'returns error when product_id is absent' do
          post '/api/v1/order_products', 
          params: {order_product: invalid_attributes[3]},
          headers: valid_headers_for_editor   
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)).to eq("error" => "product record not found")
        end

        it 'returns error when quantity is more than a product stock' do
          post '/api/v1/order_products', 
          params: {order_product: invalid_attributes[4]},
          headers: valid_headers_for_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"error" => "Quantity exceeds available stock"})
        end

        it 'returns error when quantity is equal to 0' do
          post '/api/v1/order_products', 
          params: {order_product: invalid_attributes[5]},
          headers: valid_headers_for_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"quantity" => ["must be greater than 0"]})
        end

    end

    context 'without authorization header' do
        it 'returns a 401' do
            post '/api/v1/order_products', 
            params: {order_product: valid_attributes[0]}

            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end

  describe 'DELETE /order_products/:id' do
    let(:order_product) { FactoryBot.create(:order_product, valid_attributes[0]) }

    it 'deletes a order_product' do
        delete "/api/v1/order_products/#{order_product.id}", headers: valid_headers_for_editor      
        expect(OrderProduct.exists?(order_product.id)).to be_falsey
        expect(response).to have_http_status(:no_content)
    end
    
    context 'with non-existing order_product' do
        it 'returns a 404' do
            delete "/api/v1/order_products/500", headers: valid_headers_for_editor      
            expect(response).to have_http_status(:not_found)         
        end  
    end

    context 'without authorization header ' do
        it 'returns a 401' do
            delete "/api/v1/order_products/#{order_product.id}", headers: {}     
            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end
  
  describe 'PUT /order_products/:id' do
    let(:order_product) { FactoryBot.create(:order_product, valid_attributes[0]) }

    it 'update a order_product' do 
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {price: 57}},
        headers: valid_headers_for_editor

        expect(OrderProduct.exists?(order_product.id)).to be_truthy
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json(price: 57)
    end  

    context 'with invalid attributes' do
      it 'returns error when price is not a number ' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {price: "hello"}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq({"price" => ["is not a number"]})

      end

      it 'returns error when quantity is not a number ' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {quantity: "hello"}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq({"quantity" => ["is not a number"]})

      end

      it 'returns error when quantity is absent' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {quantity: " "}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq({"quantity" => ["can't be blank", "is not a number"]})
      end

      it 'returns error when price is absent' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {price: " "}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq({"price" => ["can't be blank", "is not a number"]})

      end

      it 'returns error when order_id is absent' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {order_id: "invalid_id"}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq({"order" => ["must exist"]})

      end

      it 'returns error when product_id is absent' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {product_id: "invalid_id"}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq({"product" => ["must exist"]})

      end

      it 'returns error when quantity is more than a product stock' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {quantity: 15}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
        expect(JSON.parse(response.body)).to eq("error" => "Quantity exceeds available stock")

      end

      it 'returns error when quantity is equal to 0' do
        put "/api/v1/order_products/#{order_product.id}", 
        params: {order_product: {quantity: 0}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)  
        expect(JSON.parse(response.body)).to eq({"quantity" => ["must be greater than 0"]})
  
      end
    end

    context 'with non-existing product' do
        it 'returns a 404' do
            put "/api/v1/order_products/500", 
            params: {product: {price: 105}},
            headers: valid_headers_for_editor

            expect(response).to have_http_status(:not_found)         
        end  
    end

    context 'missing authorization header ' do
        it 'returns a 401' do
            put "/api/v1/order_products/#{order_product.id}", headers: {}     
            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end
end
