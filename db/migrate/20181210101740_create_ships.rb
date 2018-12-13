class CreateShips < ActiveRecord::Migration[5.1]
  def change
    create_table :ships do |t|
      t.string :name
      t.references :pirate, foreign_key: true

      t.timestamps
    end
  end
end
