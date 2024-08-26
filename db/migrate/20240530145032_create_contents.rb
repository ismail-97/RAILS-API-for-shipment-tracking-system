class CreateContents < ActiveRecord::Migration[7.1]
  def change
    create_table :contents do |t|
      t.string :type
      t.integer :weight
      t.integer :items_number
      t.integer :kg_price
      t.references :shipment, null: false, foreign_key: true

      t.timestamps
    end
  end
end
