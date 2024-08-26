class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.string :product_type
      t.decimal :stock, precision: 10, scale: 2
      t.decimal :price, precision: 10, scale: 2

      t.timestamps
    end
  end
end
