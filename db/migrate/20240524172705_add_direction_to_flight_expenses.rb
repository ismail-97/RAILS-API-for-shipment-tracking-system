class AddDirectionToFlightExpenses < ActiveRecord::Migration[7.1]
  def change
    add_column :flight_expenses, :direction, :string
  end
end
