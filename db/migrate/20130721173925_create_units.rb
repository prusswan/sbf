class CreateUnits < ActiveRecord::Migration
  def change
    create_table :units do |t|
      t.string :no,                     null: false
      t.string :price,                  null: false
      t.string :area,                   null: false
      t.string :flat_type,              null: false
      t.references :block, index: true, null: false

      t.timestamps
    end

    add_index :units, [:no, :block_id], unique: true
    add_index :units, :flat_type
  end
end
