class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.date :order_date
      t.integer :total
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
