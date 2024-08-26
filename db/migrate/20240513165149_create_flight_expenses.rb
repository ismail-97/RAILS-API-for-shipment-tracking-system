class CreateFlightExpenses < ActiveRecord::Migration[7.1]
  def change
    create_table :flight_expenses do |t|
      t.string :expense_type
      t.integer :amount

      t.timestamps
    end
  end
end
