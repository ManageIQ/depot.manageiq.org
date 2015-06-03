require 'spec_helper'

describe Collaborator do
  context 'associations' do
    it { should belong_to(:resourceable) }
    it { should belong_to(:user) }
  end

  context 'validations' do
    it { should validate_presence_of(:resourceable) }

    it 'validates the uniqueness of resourceable id scoped to user id and resourceable type' do
      extension = create(:extension)
      tool = create(:tool)
      user = create(:user)

      original_extension_collaborator = Collaborator.create(user: user, resourceable: extension)
      original_tool_collaborator = Collaborator.create(user: user, resourceable: tool)
      duplicate_extension_collaborator = Collaborator.create(user: user, resourceable: extension)

      expect(original_extension_collaborator.errors[:resourceable_id].size).to be 0
      expect(original_tool_collaborator.errors[:resourceable_id].size).to be 0
      expect(duplicate_extension_collaborator.errors[:resourceable_id].size).to be 1
    end
  end

  it 'facilitates the transfer of ownership' do
    sally = create(:user)
    hank = create(:user)
    extension = create(:extension, owner: sally)
    extension_collaborator = create(:extension_collaborator, resourceable: extension, user: hank)
    extension_collaborator.transfer_ownership
    expect(extension.owner).to eql(hank)
    expect(extension.collaborator_users).to include(sally)
    expect(extension.collaborator_users).to_not include(hank)
  end
end
