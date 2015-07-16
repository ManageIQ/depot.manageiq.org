class Tag < ActiveRecord::Base
  DEFAULT_TAGS = ["automate", "aws", "build", "data model", "dev", "policy", "policies", "events", "reports", "dashboard", "widgets", "dialogs", "vmware", "scvmm", "rhevm", "networking", "dynamic dialogs", "integration", "buttons", "spam", "configuration management", "puppet", "chef", "ansible", "soap", "rest API", "alarms", "email", "services", "catalog items", "catalog bundles", "CMDB", "rails", "ruby", "OpenStack", "Hyper-V", "RHEV", "oVirt", "vSphere", "The Foreman", "Kubernetes"].map(&:downcase)

  has_many :taggings
end
