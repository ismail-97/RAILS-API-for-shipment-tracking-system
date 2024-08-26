class CreateFlights < ActiveRecord::Migration[7.1]
  def change
    create_table :flights do |t|
      t.date :flight_date
      t.string :ticket_no
      t.integer :ticket_price
      t.string :airline

      t.timestamps
    end
  end
end
