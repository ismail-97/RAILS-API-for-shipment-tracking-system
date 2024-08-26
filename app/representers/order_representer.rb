class OrderRepresenter
    def initialize(order)
        @order = order   
    end  

    def as_json
            {
                id: order.id,
                order_date: order.order_date,
                total: order.total,
                customer_id: order.customer_id,
            }  
    end

    private

    attr_reader :order
end