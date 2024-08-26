class CreateShipments < ActiveRecord::Migration[7.1]
  def change
    create_table :shipments do |t|
      t.integer :items_number
      t.integer :weight
      t.string :contents
      t.string :status

      t.timestamps
    end
  end
end
