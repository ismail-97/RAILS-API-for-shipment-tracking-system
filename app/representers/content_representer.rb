class ContentRepresenter
    def initialize(content)
        @content = content   
    end  

    def as_json
        {
            id: content.id,
            content_type: content.content_type,
            weight: content.weight,
            items_number: content.items_number,
            kg_price: content.kg_price,
            shipment_id: content.shipment_id
        }  
    end

    private

    attr_reader :content
end