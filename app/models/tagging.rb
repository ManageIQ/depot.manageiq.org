class Tagging < ActiveRecord::Base
  belongs_to :taggable
  belongs_to :tag
end
