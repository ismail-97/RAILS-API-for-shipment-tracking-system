class RemoveEditorIdFromCustomers < ActiveRecord::Migration[7.1]
  def change
    remove_column :customers, :editor_id
  end
end
