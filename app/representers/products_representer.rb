class ProductsRepresenter
    def initialize(products)
        @products = products   
    end  

    def as_json
        products.map do |product|
            {
                id: product.id,
                product_type: product.product_type,
                stock: product.stock.to_f,
                price: product.price.to_f,
            }  
        end
    end

    private

    attr_reader :products
end