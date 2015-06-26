namespace :data do
  task :default_tags do
    tags = ["automate", "aws", "build", "data model", "dev", "policy", "policies", "events", "reports", "dashboard", "widgets", "dialogs", "vmware", "scvmm", "rhevm", "networking", "dynamic dialogs", "integration", "buttons", "spam", "configuration management", "puppet", "chef", "ansible", "soap", "rest API", "alarms", "email", "services", "catalog items", "catalog bundles", "CMDB", "rails", "ruby"]
    tags.each { |t| Tag.where(name: t).first_or_create }
  end
end
