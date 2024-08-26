class AddTripTypeToFlights < ActiveRecord::Migration[7.1]
  def change
    add_column :flights, :trip_type, :string
  end
end
