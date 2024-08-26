class OrderProductRepresenter
    def initialize(order_product)
        @order_product = order_product   
    end  

    def as_json
        {
            id: @order_product.id,
            quantity: @order_product.quantity.to_f,
            price: @order_product.price.to_f,
            order_id: @order_product.order_id,
            product_id: @order_product.product_id
        }  
    end

    private

    attr_reader :order_product
end