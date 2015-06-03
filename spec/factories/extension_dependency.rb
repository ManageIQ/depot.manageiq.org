FactoryGirl.define do
  factory :extension_dependency do
    association :extension_version
    association :extension

    name 'apt'
    version_constraint '>= 0.1.0'
  end
end
