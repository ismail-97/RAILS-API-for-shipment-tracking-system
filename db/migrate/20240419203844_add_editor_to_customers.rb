class AddEditorToCustomers < ActiveRecord::Migration[7.1]
  def change
    add_reference :customers, :editor
  end
end
