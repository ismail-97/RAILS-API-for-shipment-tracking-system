class TravelersRepresenter
    def initialize(travelers)
        @travelers = travelers   
    end  

    def as_json
        travelers.map do |traveler|
            {
                id: traveler.id,
                name: traveler.name,
                phone: traveler.phone,
                editor_id: traveler.editor_id
            }  
        end
    end

    private

    attr_reader :travelers
end