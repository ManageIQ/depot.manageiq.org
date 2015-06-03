require 'spec_helper'

describe CollaboratorAuthorizer do
  let(:sally) { create(:user) }
  let(:hank) { create(:user) }
  let(:extension) { create(:extension, owner: sally) }
  let(:extension_collaborator) { create(:extension_collaborator, resourceable: extension, user: hank) }

  context 'as the extension owner' do
    subject { described_class.new(sally, extension_collaborator) }

    it { should permit_authorization(:transfer) }
    it { should permit_authorization(:create) }
    it { should permit_authorization(:destroy) }
  end

  context 'as an extension collaborator' do
    subject { described_class.new(hank, extension_collaborator) }

    it { should_not permit_authorization(:transfer) }
    it { should_not permit_authorization(:create) }
    it { should permit_authorization(:destroy) }
  end

  context 'as neither the owner nor a collaborator' do
    let(:pete) { create(:user) }

    subject { described_class.new(pete, extension_collaborator) }

    it { should_not permit_authorization(:transfer) }
    it { should_not permit_authorization(:create) }
    it { should_not permit_authorization(:destroy) }
  end
end
