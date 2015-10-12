class AddGithubOrganizationToExtensions < ActiveRecord::Migration
  def change
    add_reference :extensions, :github_organization, index: true
  end
end
