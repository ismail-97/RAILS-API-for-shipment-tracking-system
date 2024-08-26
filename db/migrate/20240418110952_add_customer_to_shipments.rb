class AddCustomerToShipments < ActiveRecord::Migration[7.1]
  def change
    add_reference :shipments, :customer
  end
end
