class AddPriceStrToUnits < ActiveRecord::Migration
  def change
    add_column :units, :price_str, :string
  end
end
