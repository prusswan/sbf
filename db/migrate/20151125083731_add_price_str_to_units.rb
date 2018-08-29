class AddPriceStrToUnits < ActiveRecord::Migration[4.2]
  def change
    add_column :units, :price_str, :string
  end
end
