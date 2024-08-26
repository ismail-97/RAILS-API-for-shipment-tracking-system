class FlightsRepresenter
    def initialize(flights)
        @flights = flights   
    end  

    def as_json
        @flights.map do |flight|
            {
                id: flight.id,
                flight_date: flight.flight_date,
                ticket_no: flight.ticket_no,
                ticket_price: flight.ticket_price,
                airline: flight.airline,
                traveler_id: flight.traveler_id,
                trip_type: flight.trip_type
            }  
        end
    end

    private

    attr_reader :flights
end