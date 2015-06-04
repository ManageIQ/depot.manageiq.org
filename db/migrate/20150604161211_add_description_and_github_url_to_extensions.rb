class AddDescriptionAndGithubUrlToExtensions < ActiveRecord::Migration
  def change
    add_column :extensions, :description, :string
    add_column :extensions, :github_url, :string
  end
end
