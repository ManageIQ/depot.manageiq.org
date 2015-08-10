class CreateCommitShas < ActiveRecord::Migration
  def change
    create_table :commit_shas do |t|
      t.string :sha, null: false

      t.timestamps
    end
    add_index :commit_shas, :sha, unique: true
  end
end
