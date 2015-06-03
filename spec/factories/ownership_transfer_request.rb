FactoryGirl.define do
  factory :ownership_transfer_request do
    association :extension
    association :recipient, factory: :user
    association :sender, factory: :user
  end
end
