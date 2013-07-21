class CreateBlocks < ActiveRecord::Migration
  def change
    create_table :blocks do |t|
      t.string :no,            null: false
      t.string :street,        null: false
      t.string :estate,        null: false
      t.string :probable_date
      t.string :delivery_date, null: false
      t.string :lease_start,   null: false
      t.string :ethnic_quota,  null: false

      t.timestamps
    end

    add_index :blocks, [:no, :street], unique: true
  end
end
