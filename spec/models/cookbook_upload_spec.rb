require 'and_feathers'
require 'and_feathers/gzipped_tarball'
require 'spec_helper'
require 'tempfile'

describe CookbookUpload do
  describe '#finish' do
    before do
      create(:category, name: 'Other')
    end

    let(:cookbook) do
      JSON.dump('category' => 'Other')
    end

    let(:user) do
      create(:user)
    end

    it 'creates a new cookbook if the given name is original and assigns it to a user' do
      tarball = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')

      upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)

      expect do
        upload.finish
      end.to change(user.owned_cookbooks, :count).by(1)
    end

    it "doesn't change the owner if a collaborator uploads a new version" do
      tarball_one = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')
      tarball_two = File.open('spec/support/cookbook_fixtures/redis-test-v2.tgz')

      CookbookUpload.new(user, cookbook: cookbook, tarball: tarball_one).finish

      collaborator = create(:user)

      CookbookUpload.new(collaborator, cookbook: cookbook, tarball: tarball_two).finish do |_, result|
        expect(result.owner).to eql(user)
        expect(result.owner).to_not eql(collaborator)
      end
    end

    it 'updates the existing cookbook if the given name is a duplicate' do
      tarball_one = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')
      tarball_two = File.open('spec/support/cookbook_fixtures/redis-test-v2.tgz')

      CookbookUpload.new(user, cookbook: cookbook, tarball: tarball_one).finish

      update = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball_two)

      expect do
        update.finish
      end.to_not change(Cookbook, :count)
    end

    it 'creates a new version of the cookbook if the given name is a duplicate' do
      tarball_one = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')
      tarball_two = File.open('spec/support/cookbook_fixtures/redis-test-v2.tgz')

      cookbook_record = CookbookUpload.new(
        user,
        cookbook: cookbook,
        tarball: tarball_one
      ).finish do |_, result|
        result
      end

      update = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball_two)

      expect do
        update.finish
      end.to change(cookbook_record.cookbook_versions, :count).by(1)
    end

    it 'yields empty errors if the cookbook and tarball are workable' do
      tarball = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')

      upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors).to be_empty
    end

    context 'privacy' do
      after { ENV['ENFORCE_PRIVACY'] = nil }

      it 'returns an error if privacy is being enforced and a private cookbook is uploaded' do
        ENV['ENFORCE_PRIVACY'] = 'true'

        tarball = File.open('spec/support/cookbook_fixtures/private-cookbook.tgz')
        upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)
        errors = upload.finish { |e, _| e }
        expect(errors.full_messages).to include('Private cookbook upload not allowed')
      end

      it 'allows private cookbook uploads if private is not being enforced' do
        ENV['ENFORCE_PRIVACY'] = 'false'

        tarball = File.open('spec/support/cookbook_fixtures/private-cookbook.tgz')
        upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)
        errors = upload.finish { |e, _| e }
        expect(errors).to be_empty
      end
    end

    it 'yields the cookbook version if the cookbook and tarball are workable' do
      tarball = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')

      upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)
      version = upload.finish { |_, _, v| v }

      expect(version).to be_present
    end

    it 'yields the cookbook version if the README has no extension' do
      tarball = File.open('spec/support/cookbook_fixtures/readme-no-extension.tgz')

      upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)
      version = upload.finish { |_, _, v| v }

      expect(version).to be_present
    end

    it 'yields an error if the cookbook is not valid JSON' do
      upload = CookbookUpload.new(user, cookbook: 'ack!', tarball: 'tarball')
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.cookbook_not_json'))
    end

    it 'yields an error if the tarball does not seem to be an uploaded File' do
      upload = CookbookUpload.new(user, cookbook: '{}', tarball: 'cool')
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.tarball_has_no_path'))
    end

    it 'yields an error if the tarball is not GZipped' do
      tarball = File.open('spec/support/cookbook_fixtures/not-actually-gzipped.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.tarball_not_gzipped'))
    end

    it 'yields an error if the tarball is corrupted' do
      tarball = File.open('spec/support/cookbook_fixtures/corrupted-tarball.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.tarball_corrupt', error: 'tar is corrupt, name contains null byte'))
    end

    it 'yields an error if the tarball has no metadata.json entry' do
      tarball = File.open('spec/support/cookbook_fixtures/no-metadata-or-readme.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.missing_metadata'))
    end

    it 'yields an error if the tarball has no README entry' do
      tarball = File.open('spec/support/cookbook_fixtures/no-metadata-or-readme.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.missing_readme'))
    end

    it 'yields an error if the tarball has a zero-length README entry' do
      tarball = File.open('spec/support/cookbook_fixtures/zero-length-readme.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.missing_readme'))
    end

    it "yields an error if the tarball's metadata.json is not actually JSON" do
      tarball = File.open('spec/support/cookbook_fixtures/invalid-metadata-json.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.metadata_not_json'))
    end

    it 'yields an error if the metadata.json has a malformed platforms hash' do
      tarball = Tempfile.new('bad_platforms', 'tmp').tap do |file|
        io = AndFeathers.build('cookbook') do |cookbook|
          cookbook.file('metadata.json') { JSON.dump(platforms: '') }
        end.to_io(AndFeathers::GzippedTarball)

        file.write(io.read)
        file.rewind
      end

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.invalid_metadata'))
    end

    it 'yields an error if the metadata.json has a malformed dependencies hash' do
      tarball = Tempfile.new('bad_dependencies', 'tmp').tap do |file|
        io = AndFeathers.build('cookbook') do |cookbook|
          cookbook.file('metadata.json') { JSON.dump(dependencies: '') }
        end.to_io(AndFeathers::GzippedTarball)

        file.write(io.read)
        file.rewind
      end

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).
        to include(I18n.t('api.error_messages.invalid_metadata'))
    end

    it 'does not yield an error if the cookbook parameters do not specify a category' do
      tarball = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')

      upload = CookbookUpload.new(user, cookbook: '{}', tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors.full_messages).to be_empty
    end

    it 'yields an error if the cookbook parameters specify an invalid category' do
      tarball = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')

      upload = CookbookUpload.new(
        user,
        cookbook: '{"category": "Kewl"}',
        tarball: tarball
      )
      errors = upload.finish { |e, _| e }

      error_message = I18n.t(
        'api.error_messages.non_existent_category',
        category_name: 'Kewl'
      )

      expect(errors.full_messages).to include(error_message)
    end

    it 'yields an error if the version uniqueness database constraint is violated' do
      tarball = File.open('spec/support/cookbook_fixtures/redis-test-v1.tgz')
      user = create(:user)

      CookbookUpload.new(user, cookbook: cookbook, tarball: tarball).finish

      allow_any_instance_of(ActiveRecord::Validations::UniquenessValidator).
        to receive(:validate_each)

      upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)

      errors = upload.finish { |e, _| e }

      message = %{
        redis-test (0.1.0) already exists. A cookbook's version number must be
        unique.
      }.squish

      expect(errors.full_messages).to include(message)
    end

    it 'yields an error if any of the associated models have errors' do
      tarball = File.open('spec/support/cookbook_fixtures/invalid-platforms-and-dependencies.tgz')
      upload = CookbookUpload.new(user, cookbook: cookbook, tarball: tarball)
      errors = upload.finish { |e, _| e }

      expect(errors).to_not be_empty
    end
  end
end
