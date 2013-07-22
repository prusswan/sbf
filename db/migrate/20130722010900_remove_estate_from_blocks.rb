class RemoveEstateFromBlocks < ActiveRecord::Migration
  def change
    remove_column :blocks, :estate, :string
  end
end
