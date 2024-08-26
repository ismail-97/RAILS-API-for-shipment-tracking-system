class FlightExpenseRepresenter
    def initialize(flight_expense)
        @flight_expense = flight_expense  
    end  

    def as_json
        {
            id: @flight_expense.id,
            expense_type: @flight_expense.expense_type,
            amount: @flight_expense.amount,
            flight_id: @flight_expense.flight_id,
            direction: @flight_expense.direction
        }  
    end

    private

    attr_reader :flight_expense
end