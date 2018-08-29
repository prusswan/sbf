class AddEstateIdToBlock < ActiveRecord::Migration[4.2]
  def change
    add_reference :blocks, :estate, index: true, null: false
  end
end
