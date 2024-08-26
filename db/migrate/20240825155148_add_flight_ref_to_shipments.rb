class AddFlightRefToShipments < ActiveRecord::Migration[7.1]
  def change
    add_reference :shipments, :flight, foreign_key: true
  end
end
