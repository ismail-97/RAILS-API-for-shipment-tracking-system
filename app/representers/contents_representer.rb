class ContentsRepresenter
    def initialize(contents)
        @contents = contents   
    end  

    def as_json
        @contents.map do |content|
            {
                id: content.id,
                content_type: content.content_type,
                weight: content.weight,
                items_number: content.items_number,
                kg_price: content.kg_price,
                shipment_id: content.shipment_id
            }  
        end
    end

    private

    attr_reader :contents
end