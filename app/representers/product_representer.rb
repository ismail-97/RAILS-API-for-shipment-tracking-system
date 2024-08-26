class ProductRepresenter
    def initialize(product)
        @product = product   
    end  

    def as_json
        {
            id: @product.id,
            product_type: @product.product_type,
            stock: @product.stock.to_f,
            price: @product.price.to_f,
        }
    end

    private

    attr_reader :product
end