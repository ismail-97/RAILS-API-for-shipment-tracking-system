class AddEditorRefToTravelers < ActiveRecord::Migration[7.1]
  def change
    add_reference :travelers, :editor, null: false, foreign_key: true
  end
end
