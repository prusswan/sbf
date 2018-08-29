class RemoveEstateFromBlocks < ActiveRecord::Migration[4.2]
  def change
    remove_column :blocks, :estate, :string
  end
end
