require 'spec_helper'

describe ExtensionUpload::Metadata do
  describe 'setting the platforms attribute' do
    it 'fails loudly if Hash coercion fails' do
      expect do
        ExtensionUpload::Metadata.new(platforms: '')
      end.to raise_error(Virtus::CoercionError)
    end

    it 'can coerce Arrays into Hashes' do
      metadata = ExtensionUpload::Metadata.new(platforms: ['ubuntu'])

      expect(metadata.platforms).to eql('ubuntu' => nil)

      metadata = ExtensionUpload::Metadata.new(platforms: ['ubuntu', '1.0.0'])

      expect(metadata.platforms).to eql('ubuntu' => nil, '1.0.0' => nil)
    end

    it 'accepts a Hash mapping Strings to Strings' do
      metadata = ExtensionUpload::Metadata.new(platforms: { 'ubuntu' => 'cool' })

      expect(metadata.platforms).to eql('ubuntu' => 'cool')
    end
  end
end
