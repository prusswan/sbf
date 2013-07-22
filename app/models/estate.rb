class Estate < ActiveRecord::Base
  has_many :blocks
  has_many :units, through: :blocks
end
