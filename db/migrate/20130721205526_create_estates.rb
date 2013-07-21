class CreateEstates < ActiveRecord::Migration
  def change
    create_table :estates do |t|
      t.string :name,   null: false
      t.integer :total, null: false

      t.timestamps
    end

    add_index :estates, :name, unique: true
  end
end
