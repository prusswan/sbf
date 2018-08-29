class RemoveEthnicQuotaFromBlocks < ActiveRecord::Migration[4.2]
  def change
    remove_column :blocks, :ethnic_quota, :string
  end
end
