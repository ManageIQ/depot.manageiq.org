require 'spec_feature_helper'

feature 'tools and cookbooks can be searched for', use_poltergeist: true do
  let!(:tool) { create(:tool, name: 'Berkshelf') }
  before { visit '/' }

  it 'returns results for tools' do
    within '.search_bar' do
      follow_relation 'toggle-search-types'
      follow_relation 'toggle-tool-search'
      fill_in 'q', with: 'berkshelf'
      submit_form
    end

    expect(page).to have_content('Berkshelf')
    expect(page).to have_no_content('.no-results')
  end

end
