class FlightRepresenter
    def initialize(flight)
        @flight = flight   
    end  

    def as_json
        {
            id: @flight.id,
            flight_date: @flight.flight_date,
            ticket_no: @flight.ticket_no,
            ticket_price: @flight.ticket_price,
            airline: @flight.airline,
            traveler_id: @flight.traveler_id,
            trip_type: @flight.trip_type
        }  
    end

    private

    attr_reader :flight
end