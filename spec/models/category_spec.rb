require 'spec_helper'

describe Category do
  context 'associations' do
    it { should have_many(:extensions) }
  end

  context 'slugs' do
    it 'should automatically add a slug before saving' do
      c = create(:category, name: 'Web Servers')
      expect(c.slug).to eql('web-servers')
    end
  end
end
