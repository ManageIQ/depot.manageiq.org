require "spec_helper"

describe AddExtensionCollaborator do
  let(:extension) { double(:extension) }
  let(:github_user) { double(:github_user) }

  let(:service) { double(:service) }

  let(:user) { double(:user) }
  let(:account) { double(:account) }

  subject { AddExtensionCollaborator.new(extension, github_user) }

  before do
    allow(ActiveRecord::Base).to receive(:transaction).and_yield
    stub_const("EnsureGithubUserAndAccount", Class.new)
  end

  it "ensures the existence of the user and account then creates the collaborator" do
    expect(EnsureGithubUserAndAccount).to receive(:new).with(github_user) { service }
    expect(service).to receive(:process!).and_return([user, account])
    expect(Collaborator).to receive(:create).with(user: user, resourceable: extension)
    subject.process!
  end
end
