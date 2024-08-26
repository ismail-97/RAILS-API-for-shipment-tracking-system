class CreateEditors < ActiveRecord::Migration[7.1]
  def change
    create_table :editors do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.boolean :super_editor

      t.timestamps
    end
  end
end
