class RemovePhoneFromCustomers < ActiveRecord::Migration[7.1]
  def change
    remove_column :customers, :phone, :string
  end
end
