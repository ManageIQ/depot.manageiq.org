class Tagging < ActiveRecord::Base
  belongs_to :taggable, polymorphic: true
  belongs_to :tag

  def self.add(name)
    create(tag: Tag.where(name: name.strip).first_or_create)
  end
end
