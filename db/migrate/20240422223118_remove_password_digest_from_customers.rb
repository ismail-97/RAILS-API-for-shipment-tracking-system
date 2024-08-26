class RemovePasswordDigestFromCustomers < ActiveRecord::Migration[7.1]
  def change
    remove_column :customers, :password_digest, :string
  end
end
