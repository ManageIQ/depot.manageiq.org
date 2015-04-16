require 'spec_helper'

describe ContributorList do
  context '#each' do
    it "yields a user, and that user's github accounts" do
      user = create(:user)
      # chef_account = user.accounts.for('github').first!
      github_account = create(:account, provider: 'github', user: user)

      contributor_list = ContributorList.new(User.where(id: user.id))

      expect do |b|
        contributor_list.each(&b)
      end.to yield_with_args(user, github_account)
    end

    it 'eager loads the accounts' do

      Account.delete_all
      User.delete_all

      user = create(:user)
      create(:account, provider: 'github', user: user)

      github_account = user.github_account

      contributor_list = ContributorList.new(User.where(id: user.id))
      
      expect do |b|
        contributor_list.each(&b)
      end.to yield_with_args(user, github_account)
    end
  end
end
