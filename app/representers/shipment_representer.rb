class ShipmentRepresenter
    def initialize(shipment)
        @shipment = shipment
    end  

    def as_json
        {
            id: @shipment.id,
            direction: @shipment.direction,
            total: @shipment.total,
            customer_id: @shipment.customer_id,
            editor_id: @shipment.editor_id,
            flight_id: @shipment.flight_id
        }  
    end

    private

    attr_reader :shipment
end