class RemoveEthnicQuotaFromBlocks < ActiveRecord::Migration
  def change
    remove_column :blocks, :ethnic_quota, :string
  end
end
