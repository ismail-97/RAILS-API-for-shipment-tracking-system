class AddForeignKeyToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_reference :customers, :editor, foreign_key: true
  end
end
