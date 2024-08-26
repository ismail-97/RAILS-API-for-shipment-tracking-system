class CreateOrderProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :order_products do |t|
      t.decimal :quantity, precision: 10, scale: 2
      t.string :product_type
      t.decimal :price, precision: 10, scale: 2
      t.references :order, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
