class AddLinkToBlocks < ActiveRecord::Migration
  def change
    add_column :blocks, :link, :string
  end
end
