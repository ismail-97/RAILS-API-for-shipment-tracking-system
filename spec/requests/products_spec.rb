require 'rails_helper'

RSpec.describe "Products API", type: :request do

  let(:super_editor) {FactoryBot.create(:editor, name: "admin", email: "admin@gmail.com", password: '123456', super_editor: true)}
  let(:editor) {FactoryBot.create(:editor, name: "admin2", email: "admin2@gmail.com", password: '123456', super_editor: false)}

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
    {product_type: "turkish cheese", stock: 10.0, price: 200.0},
    {product_type: "sunflower", stock: 5.0, price: 300.0},
  ]
  }

  let(:invalid_attributes) {[
    {stock: 10, price: 300}, #absence of product_type
    {product_type: "sunflower", price: 300}, #absence of stock
    {product_type: "sunflower", stock: 5}, #absence of price
    {product_type: "sunflower", stock: 5.0, price: "dog"},
    {product_type: "sunflower", stock: "dog", price: "300"},
  ]
  }


  before (:each) do
    Product.delete_all
  end 


  describe "GET /products" do
    before do
      FactoryBot.create(:product, valid_attributes[0])
      FactoryBot.create(:product, valid_attributes[1])    
    end

    context 'without query parameters' do
      before do
          get '/api/v1/products', headers: valid_headers_for_editor  
      end

      it 'returns all products' do
          expect(JSON.parse(response.body).size).to eq(2)
      end           
      
      it 'returns a 200 Success status' do
          expect(response).to have_http_status(:success)         
      end        
    end

    context 'with query parameters' do
      it 'returns a specific product depending on query parameters' do
          get '/api/v1/products', headers: valid_headers_for_editor, params: {stock: valid_attributes[1][:stock]}    
          expect(JSON.parse(response.body).size).to eq(1)
          expect(response).to have_http_status(:success)         
          expect(response.body).to include({id:2}.merge(valid_attributes[1]).to_json)
      end     

      it 'does not apply filter on parameters which is not allowed via controller' do
          get '/api/v1/products',  headers: valid_headers_for_editor, params: {total: 578}    
          expect(JSON.parse(response.body).size).to eq(2)
          expect(response).to have_http_status(:success)         
      end
    end

    context 'missing authorization header ' do
      it 'returns a 401' do
          get '/api/v1/products', headers: {}  
          expect(response).to have_http_status(:unauthorized)         
      end
    end
  end

  describe "GET /products/:id" do
    let(:product) {FactoryBot.create(:product, valid_attributes[0])}

    it 'returns a specific product' do
      get "/api/v1/products/#{product.id}", headers: valid_headers_for_editor  
      expect(JSON.parse(response.body).size).to eq(4)
      expect(response).to have_http_status(:success)      
      expect(response.body).to eq({id: product.id}.merge(valid_attributes[0]).to_json)
    end

    context 'with non existing product' do
      it 'returns a 404' do
          get "/api/v1/products/500"  
          expect(response).to have_http_status(:not_found)         
      end  
    end

    context 'missing authorization header ' do
      it 'returns a 404' do
          get '/api/v1/products/500', headers: {}  
          expect(response).to have_http_status(:not_found)         
      end
    end

  end

  describe 'POST /products' do

    context 'with valid attributes' do
        before do
          post '/api/v1/products', 
          params: {product: valid_attributes[0]}, 
          headers: valid_headers_for_editor     
        end

        it 'creates a new product' do
            expect(Product.count).to eq(1)
        end

        it 'returns a 201 Created status' do
            expect(response).to have_http_status(:created)
        end  
        
        it 'returns the created product attributes in the response' do
            expect(response.body).to eq({id: 1}.merge(valid_attributes[0]).to_json)
        end    
    end

    context 'with invalid attributes' do 
 
        it 'returns error when product_type is absent' do
            post '/api/v1/products', 
            params: {product: invalid_attributes[0]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"product_type" => ["can't be blank"]})
        end

        it 'returns error when stock is absent' do
            post '/api/v1/products', 
            params: {product: invalid_attributes[1]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"stock" => ["can't be blank", "is not a number"]})
        end

        it 'returns error when price is absent' do
            post '/api/v1/products', 
            params: {product: invalid_attributes[2]},
            headers: valid_headers_for_editor   
            expect(response).to have_http_status(:unprocessable_entity)
            expect(JSON.parse(response.body)).to eq({"price" => ["can't be blank", "is not a number"]})
        end

        it 'returns error when price is not number' do
          post '/api/v1/products', 
          params: {product: invalid_attributes[3]},
          headers: valid_headers_for_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"price" => ["is not a number"]})
        end

        it 'returns error when stock is not number' do
          post '/api/v1/products', 
          params: {product: invalid_attributes[4]},
          headers: valid_headers_for_editor   
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)).to eq({"stock" => ["is not a number"]})
        end
    end

    context 'without authorization header' do
        it 'returns a 401' do
            post '/api/v1/products', 
            params: {product: valid_attributes[0]}

            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end

  describe 'DELETE /products/:id' do
    let(:product) { FactoryBot.create(:product, valid_attributes[0]) }

    it 'deletes a product' do
        delete "/api/v1/products/#{product.id}", headers: valid_headers_for_editor      
        expect(Product.exists?(product.id)).to be_falsey
        expect(response).to have_http_status(:no_content)
    end
    
    context 'with non-existing product' do
        it 'returns a 404' do
            delete "/api/v1/products/500", headers: valid_headers_for_editor      
            expect(response).to have_http_status(:not_found)         
        end  
    end

    context 'without authorization header ' do
        it 'returns a 401' do
            delete "/api/v1/products/#{product.id}", headers: {}     
            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end
  
  describe 'PUT /products/:id' do
    let(:product) { FactoryBot.create(:product, valid_attributes[0]) }

    it 'update a product' do 
        put "/api/v1/products/#{product.id}", 
        params: {product: {price: 200}},
        headers: valid_headers_for_editor

        expect(Product.exists?(product.id)).to be_truthy
        expect(response).to have_http_status(:ok)
        expect(response.body).to include_json(price: 200)
    end  

    context 'with invalid attributes' do
      it 'returns error when price is not a number ' do
        put "/api/v1/products/#{product.id}", 
        params: {product: {price: "hello"}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
      end

      it 'returns error when stock is not a number ' do
        put "/api/v1/products/#{product.id}", 
        params: {product: {price: "hello"}},
        headers: valid_headers_for_editor

        expect(response).to have_http_status(:unprocessable_entity)   
      end

    end

    context 'with non-existing product' do
        it 'returns a 404' do
            put "/api/v1/products/500", 
            params: {product: {price: 105}},
            headers: valid_headers_for_editor

            expect(response).to have_http_status(:not_found)         
        end  
    end

    context 'missing authorization header ' do
        it 'returns a 401' do
            put "/api/v1/products/#{product.id}", headers: {}     
            expect(response).to have_http_status(:unauthorized)         
        end
    end
  end
end
