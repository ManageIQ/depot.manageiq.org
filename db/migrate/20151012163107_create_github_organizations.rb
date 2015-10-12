class CreateGithubOrganizations < ActiveRecord::Migration
  def change
    create_table :github_organizations do |t|
      t.integer :github_id, null: false, index: true
      t.string :name, null: false
      t.string :avatar_url, null: false

      t.timestamps
    end
  end
end
