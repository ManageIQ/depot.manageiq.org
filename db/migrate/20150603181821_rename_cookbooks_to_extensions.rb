class RenameCookbooksToExtensions < ActiveRecord::Migration
  def change
    # cookbook_dependencies table

    rename_column :cookbook_dependencies, :cookbook_id, :extension_id
    rename_column :cookbook_dependencies, :cookbook_version_id, :extension_version_id
    rename_table :cookbook_dependencies, :extension_dependencies

    # cookbook_followers table

    rename_column :cookbook_followers, :cookbook_id, :extension_id
    rename_table :cookbook_followers, :extension_followers

    # cookbook_version_platforms table

    rename_column :cookbook_version_platforms, :cookbook_version_id, :extension_version_id
    rename_table :cookbook_version_platforms, :extension_version_platforms

    # cookbook_versions table

    rename_column :cookbook_versions, :cookbook_id, :extension_id
    rename_table :cookbook_versions, :extension_versions

    # cookbooks table

    rename_column :cookbooks, :cookbook_followers_count, :extension_followers_count
    rename_table :cookbooks, :extensions

    # ownership_transfer_requests table

    rename_column :ownership_transfer_requests, :cookbook_id, :extension_id
  end
end
