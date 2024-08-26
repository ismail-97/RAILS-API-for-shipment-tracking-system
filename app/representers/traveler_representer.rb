class TravelerRepresenter
    def initialize(traveler)
        @traveler = traveler
    end  

    def as_json
        {
            id: @traveler.id,
            name: @traveler.name,
            phone: @traveler.phone,
            editor_id: @traveler.editor_id
        }  
    end

    private

    attr_reader :traveler
end