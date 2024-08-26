class CustomersRepresenter
    def initialize(customers)
        @customers = customers   
    end  

    def as_json
        customers.map do |customer|
            {
                id: customer.id,
                name: customer.name,
                phone: customer.phone,
                editor_id: customer.editor_id
            }  
        end
    end

    private

    attr_reader :customers
end