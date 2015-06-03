require 'spec_feature_helper'

feature 'admin transfers extension ownership' do
  let(:extension) { create(:extension) }
  let(:new_owner) { create(:user) }

  before do
    sign_in(create(:admin))
    visit extension_path(extension)
    follow_relation 'transfer_ownership'

    within '#transfer' do
      find('#extension_user_id').set(new_owner.id)
      submit_form
    end
  end

  it 'displays a success message' do
    expect_to_see_success_message
  end

  it 'changes the owner' do
    expect(page).to have_content(new_owner.username)
  end
end
