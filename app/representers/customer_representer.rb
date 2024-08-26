class CustomerRepresenter
    def initialize(customer)
        @customer = customer
    end  

    def as_json
        {
            id: @customer.id,
            name: @customer.name,
            phone: @customer.phone,
            editor_id: @customer.editor_id
        }  
    end

    private

    attr_reader :customer
end