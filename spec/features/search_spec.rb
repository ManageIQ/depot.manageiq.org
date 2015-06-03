require 'spec_feature_helper'

feature 'tools and cookbooks can be searched for', use_poltergeist: true do
  let!(:cookbook) { create(:cookbook, name: 'apache') }
  before { visit '/' }

  it 'returns results for cookbooks' do
    within '.search_bar' do
      follow_relation 'toggle-search-types'
      follow_relation 'toggle-cookbook-search'
      fill_in 'q', with: 'apache'
      submit_form
    end

    expect(page).to have_content('apache')
    expect(page).to have_no_content('.no-results')
  end
end
