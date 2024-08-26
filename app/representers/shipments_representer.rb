class ShipmentsRepresenter
    def initialize(shipments)
        @shipments = shipments   
    end  

    def as_json
        @shipments.map do |shipment|
            {
                id: shipment.id,
                direction: shipment.direction,
                total: shipment.total,
                customer_id: shipment.customer_id,
                editor_id: shipment.editor_id,
                flight_id: shipment.flight_id

            }  
        end
    end

    private

    attr_reader :shipments
end