class Block < ActiveRecord::Base
  has_many :units

  belongs_to :estate
end
