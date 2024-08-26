class OrderProductsRepresenter
    def initialize(order_products)
        @order_products = order_products   
    end  

    def as_json
        @order_products.map do |order_product|
            {
                id: order_product.id,
                quantity: order_product.quantity.to_f,
                price: order_product.price.to_f,
                order_id: order_product.order_id,
                product_id: order_product.product_id
            }  
        end
    end

    private

    attr_reader :order_products
end