class FixNumericColumns < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        rename_column :units, :price, :price_str
        rename_column :units, :area,  :area_str
        add_column    :units, :price, :integer, null: false
        add_column    :units, :area,  :integer, null: false

        Unit.all.each do |u|
          u.update_attributes({
            price: u.price_str.gsub(/\D/,'').to_i,
            area:  u.area_str.gsub(/\D/,'').to_i
          }, :without_protection => true)
        end

        remove_column :units, :price_str, :string
        remove_column :units, :area_str, :string
      end

      dir.down do
        add_column    :units, :price_str, :string, null: false
        add_column    :units, :area_str,  :string, null: false

        Unit.all.each do |u|
          u.update_attributes({
            price_str: u.price.to_s,
            area_str:  u.area.to_s
          }, :without_protection => true)
        end

        remove_column :units, :price, :integer
        remove_column :units, :area,  :integer
        rename_column :units, :price_str, :price
        rename_column :units, :area_str,  :area
      end
    end
  end
end
