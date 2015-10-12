namespace :data do
  task :default_tags do
    tags = ["automate", "aws", "build", "data model", "dev", "policy", "policies", "events", "reports", "dashboard", "widgets", "dialogs", "vmware", "scvmm", "rhevm", "networking", "dynamic dialogs", "integration", "buttons", "spam", "configuration management", "puppet", "chef", "ansible", "soap", "rest API", "alarms", "email", "services", "catalog items", "catalog bundles", "CMDB", "rails", "ruby"]
    tags.each { |t| Tag.where(name: t).first_or_create }
  end

  task :github_organizations do
    Extension.includes(:owner).all.each do |e|
      gh = e.owner.octokit
      info = gh.repo(e.github_repo)

      if org = info[:organization]
        e.github_organization = GithubOrganization.where(github_id: org[:id]).first_or_create!(
          name: org[:login],
          avatar_url: org[:avatar_url]
        )
        e.save
      end
    end
  end

  task :owner_names do
    Extension.includes(:owner).all.each do |e|
      if e.github_organization
        e.update_attribute(:owner_name, e.github_organization.name)
      else
        e.update_attribute(:owner_name, e.owner.username)
      end
    end
  end
end
