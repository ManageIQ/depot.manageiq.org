FactoryGirl.define do
  factory :extension_collaborator, class: 'Collaborator' do
    association :resourceable, factory: :extension
    association :user
  end

  factory :tool_collaborator, class: 'Collaborator' do
    association :resourceable, factory: :tool
    association :user
  end
end
