class AddFlightRefToFlightExpenses < ActiveRecord::Migration[7.1]
  def change
    add_reference :flight_expenses, :flight, null: false, foreign_key: true
  end
end
