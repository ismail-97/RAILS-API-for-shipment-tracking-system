class AddEditorToShipments < ActiveRecord::Migration[7.1]
  def change
    add_reference :shipments, :editor
  end
end
