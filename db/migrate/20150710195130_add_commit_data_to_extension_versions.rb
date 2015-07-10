class AddCommitDataToExtensionVersions < ActiveRecord::Migration
  def change
    add_column :extension_versions, :last_commit_string, :string
    add_column :extension_versions, :last_commit_at, :datetime
    add_column :extension_versions, :last_commit_sha, :string
    add_column :extension_versions, :last_commit_url, :string
  end
end
