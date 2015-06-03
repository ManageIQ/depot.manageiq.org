require 'spec_helper'

describe 'users/followed_extension_activity.atom.builder' do
  let!(:test_extension_5_0) do
    create(
      :extension_version,
      version: '5.0',
      description: 'this extension is so rad',
      changelog: 'we added so much stuff!',
      changelog_extension: 'md'
    )
  end

  let!(:test_extension) do
    create(
      :extension,
      name: 'test',
      extension_versions_count: 0,
      extension_versions: [test_extension_5_0]
    )
  end

  let!(:test_extension2) do
    create(
      :extension,
      name: 'test-2',
      extension_versions: [
        create(:extension_version, description: 'test extension')
      ],
      extension_versions_count: 0
    )
  end

  before { assign(:user, double(User, username: 'johndoe')) }

  describe 'some activity' do
    before do
      assign(
        :followed_extension_activity,
        [test_extension.extension_versions.first, test_extension2.extension_versions.first]
      )

      render
    end

    it 'displays the feed title' do
      expect(xml_body['feed']['title']).to eql("johndoe's Followed Extension Activity")
    end

    it 'displays when the feed was updated' do
      expect(Date.parse(xml_body['feed']['updated'])).to_not be_nil
    end

    it 'displays followed extension activity entries' do
      expect(xml_body['feed']['entry'].count).to eql(2)
    end

    it 'displays information about extension activity' do
      activity = xml_body['feed']['entry'].first

      expect(activity['title']).to match(/#{test_extension.name}/)
      expect(activity['content']).to match(/this extension is so rad/)
      expect(activity['content']).to match(/we added so much stuff/)
      expect(activity['author']['name']).to eql(test_extension.maintainer)
      expect(activity['author']['uri']).to eql(user_url(test_extension.owner))
      expect(activity['link']['href']).
        to eql(extension_version_url(test_extension, test_extension.extension_versions.first.version))
    end
  end

  describe 'no activity' do
    before do
      assign(:followed_extension_activity, [])
      render
    end

    it 'still works if @followed_extension_activity is empty' do
      expect do
        expect(Date.parse(xml_body['feed']['updated'])).to_not be_nil
      end.to_not raise_error
    end
  end
end
