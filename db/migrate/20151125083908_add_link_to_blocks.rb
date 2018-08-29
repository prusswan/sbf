class AddLinkToBlocks < ActiveRecord::Migration[4.2]
  def change
    add_column :blocks, :link, :string
  end
end
