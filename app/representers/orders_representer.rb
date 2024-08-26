class OrdersRepresenter
    def initialize(orders)
        @orders = orders   
    end  

    def as_json
        orders.map do |order|
            {
                id: order.id,
                order_date: order.order_date,
                total: order.total,
                customer_id: order.customer_id,
            }  
        end
    end

    private

    attr_reader :orders
end