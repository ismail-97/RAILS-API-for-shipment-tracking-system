class RemoveItemsNumberFromShipment < ActiveRecord::Migration[7.1]
  def change
    remove_column :shipments, :items_number, :integer
    remove_column :shipments, :weight, :integer
    remove_column :shipments, :contents, :string
    remove_column :shipments, :status, :string
  end
end
