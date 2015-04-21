require 'spec_feature_helper'

describe 'signing out' do
  it 'displays a message about oc-id' do
    sign_in(create(:user))
    sign_out

    expect(page).to have_content('You have been signed out of the Extensions Depot')
  end
end
