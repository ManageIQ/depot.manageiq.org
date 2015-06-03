require 'spec_helper'

describe ExtensionUpload::Parameters do
  include TarballHelpers

  def params(hash)
    ExtensionUpload::Parameters.new(hash)
  end

  describe '#category_name' do
    it 'is extracted from the extension JSON' do
      params = params(extension: '{"category":"Cool"}', tarball: double)

      expect(params.category_name).to eql('Cool')
    end

    it 'is blank if the extension JSON is invalid' do
      params = params(extension: 'ack!', tarball: double)

      expect(params.category_name).to eql('')
    end
  end

  describe '#metadata' do
    it 'is extracted from the tarball' do
      tarball = File.open('spec/support/extension_fixtures/redis-test-v1.tgz')

      params = params(extension: '{}', tarball: tarball)

      redis_metadata = ExtensionUpload::Metadata.new(
        name: 'redis-test',
        version: '0.1.0',
        license: 'All rights reserved',
        description: 'Installs/Configures redis-test'
      )

      expect(params.metadata).to eql(redis_metadata)
    end

    it 'is extracted from the top-level metadata.json' do
      tarball = Tempfile.new('multiple-metadata', 'tmp').tap do |file|
        io = AndFeathers.build('multiple-metadata') do |base|
          base.file('metadata.json') do
            JSON.dump(name: 'multiple')
          end
          base.file('PaxHeader/metadata.json') do
            JSON.dump(name: 'PaxHeader-multiple')
          end
        end.to_io(AndFeathers::GzippedTarball, :reverse_each)

        file.write(io.read)
        file.rewind
      end

      params = params(extension: '{}', tarball: tarball)

      expect(params.metadata.name).to eql('multiple')
    end

    it 'is blank if the tarball parameter is not a file' do
      params = params(extension: '{}', tarball: 'tarball!')

      expect(params.metadata).to eql(ExtensionUpload::Metadata.new)
    end

    it 'is blank if the tarball parameter is not GZipped' do
      file = Tempfile.open('notgzipped') { |f| f << 'metadata' }

      params = params(extension: '{}', tarball: file)

      expect(params.metadata).to eql(ExtensionUpload::Metadata.new)
    end

    it 'is blank if the tarball parameter has no metadata.json entry' do
      tarball = File.open('spec/support/extension_fixtures/no-metadata-or-readme.tgz')

      params = params(extension: '{}', tarball: tarball)

      expect(params.metadata).to eql(ExtensionUpload::Metadata.new)
    end

    it "is blank if the tarball's metadata.json entry is not actually JSON" do
      tarball = File.open('spec/support/extension_fixtures/invalid-metadata-json.tgz')

      params = params(extension: '{}', tarball: tarball)

      expect(params.metadata).to eql(ExtensionUpload::Metadata.new)
    end
  end

  describe '#readme' do
    it 'is extracted from the tarball' do
      tarball = File.open('spec/support/extension_fixtures/redis-test-v1.tgz')

      params = params(extension: '{}', tarball: tarball)

      expect(params.readme.contents).to_not be_empty
      expect(params.readme.file_extension).to eql('md')
    end

    it 'is extracted from the top-level README' do
      tarball = Tempfile.new('multiple-readme', 'tmp').tap do |file|
        io = AndFeathers.build('multiple-readme') do |base|
          base.file('metadata.json') { JSON.dump(name: 'multiple-readme') }
          base.file('README') { 'readme' }
          base.file('PaxHeader/metadata.json') do
            JSON.dump(name: 'multiple-readme')
          end
          base.file('PaxHeader/README') { 'impostor readme' }
        end.to_io(AndFeathers::GzippedTarball, :reverse_each)

        file.write(io.read)
        file.rewind
      end

      params = params(extension: '{}', tarball: tarball)

      expect(params.readme.contents).to eql('readme')
    end

    it 'is blank if the tarball parameter is not a file' do
      params = params(extension: '{}', tarball: 'tarball!')

      expect(params.readme).to eql(ExtensionUpload::Document.new)
    end

    it 'is blank if the tarball parameter is not GZipped' do
      file = Tempfile.open('notgzipped') { |f| f << 'metadata' }

      params = params(extension: '{}', tarball: file)

      expect(params.readme).to eql(ExtensionUpload::Document.new)
    end

    it 'is blank if the tarball parameter has no README entry' do
      tarball = File.open('spec/support/extension_fixtures/no-metadata-or-readme.tgz')

      params = params(extension: '{}', tarball: tarball)

      expect(params.readme).to eql(ExtensionUpload::Document.new)
    end

    it 'can have a file extension' do
      tarball = build_extension_tarball do |base|
        base.file('README.markdown') { '# README' }
      end

      params = params(extension: '{}', tarball: tarball)

      readme = ExtensionUpload::Document.new(
        contents: '# README',
        file_extension: 'markdown'
      )

      expect(params.readme).to eql(readme)
    end

    it 'has a blank file extension if the README has none' do
      tarball = build_extension_tarball do |base|
        base.file('README') { 'README' }
      end

      params = params(extension: '{}', tarball: tarball)

      readme = ExtensionUpload::Document.new(
        contents: 'README',
        file_extension: ''
      )

      expect(params.readme).to eql(readme)
    end
  end

  describe '#changelog' do
    it 'is extracted from the tarball' do
      tarball = build_extension_tarball do |base|
        base.file('CHANGELOG.md') { 'ch-ch-changes' }
      end

      params = params(extension: '{}', tarball: tarball)

      expect(params.changelog.contents).to eql('ch-ch-changes')
      expect(params.changelog.file_extension).to eql('md')
    end

    it 'is extracted from the top-level CHANGELOG' do
      tarball = build_extension_tarball do |base|
        base.file('CHANGELOG.md') { 'ch-ch-changes' }
        base.file('PaxHeader/CHANGELOG.md') { 'not these changes' }
      end

      params = params(extension: '{}', tarball: tarball)

      expect(params.changelog.contents).to eql('ch-ch-changes')
    end

    it 'is blank if the tarball parameter is not a file' do
      params = params(extension: '{}', tarball: 'tarball')

      expect(params.changelog).to eql(ExtensionUpload::Document.new)
    end

    it 'is blank if the tarball parameter is not GZipped' do
      file = Tempfile.open('notgzipped') { |f| f << 'metadata' }

      params = params(extension: '{}', tarball: file)

      expect(params.changelog).to eql(ExtensionUpload::Document.new)
    end

    it 'is blank if the tarball parameter has no CHANGELOG entry' do
      tarball = build_extension_tarball do |base|
        base.file('README.md') { '# README' }
      end

      params = params(extension: '{}', tarball: tarball)

      expect(params.changelog).to eql(ExtensionUpload::Document.new)
    end

    it 'can have an file extension' do
      tarball = build_extension_tarball do |base|
        base.file('CHANGELOG.markdown') { '# Markdown' }
      end

      params = params(extension: '{}', tarball: tarball)

      changelog = ExtensionUpload::Document.new(
        contents: '# Markdown',
        file_extension: 'markdown'
      )

      expect(params.changelog).to eql(changelog)
    end

    it 'has a blank file extension if the CHANGELOG has none' do
      tarball = build_extension_tarball do |base|
        base.file('CHANGELOG') { 'Plain text' }
      end

      params = params(extension: '{}', tarball: tarball)

      changelog = ExtensionUpload::Document.new(
        contents: 'Plain text',
        file_extension: ''
      )

      expect(params.changelog).to eql(changelog)
    end
  end
end
