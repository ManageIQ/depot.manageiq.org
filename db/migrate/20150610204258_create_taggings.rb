class CreateTaggings < ActiveRecord::Migration
  def change
    create_table :taggings do |t|
      t.references :taggable, index: true, polymorphic: true
      t.references :tag, index: true
      t.timestamps
    end

    add_index :taggings, [:taggable_id, :taggable_type, :tag_id], unique: true
  end
end
