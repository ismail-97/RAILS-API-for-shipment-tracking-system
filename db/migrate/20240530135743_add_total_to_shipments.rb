class AddTotalToShipments < ActiveRecord::Migration[7.1]
  def change
    add_column :shipments, :total, :integer
  end
end
