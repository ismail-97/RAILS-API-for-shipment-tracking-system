class AddForeignKeysToShipments < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :shipments, :customers, column: :customer_id
    add_foreign_key :shipments, :editors, column: :editor_id
  end
end
