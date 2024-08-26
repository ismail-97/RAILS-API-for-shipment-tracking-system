class AddStatusToShipment < ActiveRecord::Migration[7.1]
  def change
    add_column :shipments, :status, :string
  end
end
