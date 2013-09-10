class PopulateQuotaTable < ActiveRecord::Migration
  def up
    quota_fields = ['malay','chinese','others','flat_type','block_id']

    def parse_quota(quota_str)
      r = quota_str.match /(\d+)\D+(\d+)\D+(\d+)/
      r[1..3].map(&:to_i)
    end

    # for checking the affected blocks and flat types:
    # r3 = Block.joins(:units).joins(:estate)
    #   .select([:flat_type,'blocks.no',:street,:name,'count(distinct flat_type) as total'])
    #   .group(['blocks.no',:street,:name])
    #   .having('count(distinct flat_type) > 1')
    #   .order(['estates.name','units.flat_type','blocks.no',:street])

    blocks = Block.joins(:units).select('*') #.select('blocks.id',:street,'blocks.no',:flat_type,:ethnic_quota).distinct
    blocks.each do |block|
      next if Quota.where(flat_type: block.flat_type, block_id: block.block_id).first

      quota_info = parse_quota(block.ethnic_quota) << block.flat_type << block.block_id
      quota_hash = Hash[quota_fields.zip(quota_info)]

      puts quota_hash

      quota = Quota.where(quota_hash).first_or_create
      units = Unit.where(block_id: block.block_id, flat_type: block.flat_type)
      units.update_all(['quota_id = ?', quota.id])
    end
  end

  def down

  end
end
