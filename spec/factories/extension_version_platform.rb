FactoryGirl.define do
  factory :extension_version_platform do
    association :extension_version
    association :supported_platform
  end
end
