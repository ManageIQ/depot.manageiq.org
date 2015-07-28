class AddCommitCountToExtensionVersions < ActiveRecord::Migration
  def change
    add_column :extension_versions, :commit_count, :integer, null: false, default: 0
  end
end
