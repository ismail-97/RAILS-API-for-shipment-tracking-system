class FlightExpensesRepresenter
    def initialize(flight_expenses)
        @flight_expenses = flight_expenses   
    end  

    def as_json
        @flight_expenses.map do |flight_expense|
            {
                id: flight_expense.id,
                expense_type: flight_expense.expense_type,
                amount: flight_expense.amount,
                flight_id: flight_expense.flight_id,
                direction: flight_expense.direction
            }  
        end
    end

    private

    attr_reader :flight_expenses
end