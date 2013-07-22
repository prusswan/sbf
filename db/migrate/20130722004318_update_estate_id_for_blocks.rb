class UpdateEstateIdForBlocks < ActiveRecord::Migration
  def up
    Estate.all.each do |e|
      Block.where(estate: e.name).each { |r| r.update_attribute(:estate_id, e.id) }
    end
  end

  def down
    Estate.all.each do |e|
      Block.where(estate_id: e.id).each { |r| r.update_attribute(:estate, e.name) }
    end
  end
end
