class AddEstateIdToBlock < ActiveRecord::Migration
  def change
    add_reference :blocks, :estate, index: true, null: false
  end
end
