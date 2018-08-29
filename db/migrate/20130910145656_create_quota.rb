class CreateQuota < ActiveRecord::Migration[4.2]
  def change
    create_table :quota do |t|
      t.string :flat_type,              null: false
      t.integer :malay,                 null: false
      t.integer :chinese,               null: false
      t.integer :others,                null: false
      t.references :block, index: true, null: false

      t.timestamps
    end

    add_index :quota, [:flat_type, :block_id], unique: true
    add_reference :units, :quota, index: true, null: false
  end
end
