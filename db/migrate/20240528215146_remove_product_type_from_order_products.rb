class RemoveProductTypeFromOrderProducts < ActiveRecord::Migration[7.1]
  def change
    remove_column :order_products, :product_type, :string
  end
end
