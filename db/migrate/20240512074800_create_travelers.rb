class CreateTravelers < ActiveRecord::Migration[7.1]
  def change
    create_table :travelers do |t|
      t.string :name
      t.string :phone

      t.timestamps
    end
  end
end
