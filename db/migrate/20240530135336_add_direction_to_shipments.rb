class AddDirectionToShipments < ActiveRecord::Migration[7.1]
  def change
    add_column :shipments, :direction, :string
  end
end
