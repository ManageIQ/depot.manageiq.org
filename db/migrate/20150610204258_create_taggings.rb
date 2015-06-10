class CreateTaggings < ActiveRecord::Migration
  def change
    create_table :taggings do |t|
      t.references :taggable, index: true
      t.references :tag, index: true
      t.timestamps
    end

    add_index :taggings, [:taggable_id, :tag_id], unique: true
  end
end
