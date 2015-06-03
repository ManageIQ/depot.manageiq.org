require 'active_model/errors'
require 'extension_upload/archive'
require 'extension_upload/metadata'
require 'extension_upload/document'
require 'json'
require 'set'

class ExtensionUpload
  class Parameters
    #
    # @!attribute [r] tarball
    #   @return [File] The tarball parameter value
    #
    attr_reader :tarball

    #
    # @!attribute [r] archive
    #   @return [Archive] An interface to +tarball+
    #
    attr_reader :archive

    #
    # Creates a new set of extension upload parameters
    #
    # @raise [KeyError] if any of the +:extension+ or +:tarball+ keys are missing
    #
    # @param params [Hash] the "raw" parameters
    # @option params [String] :extension a JSON string which specifies extension
    #   attributes
    # @option params [File] :tarball the extension tarball artifact
    #
    def initialize(params)
      @extension_data = params.fetch(:extension)
      @tarball = params.fetch(:tarball)
      @archive = Archive.new(@tarball)
    end

    #
    # The category name given in the +:extension+ option. May be an empty string.
    #
    # @return [String]
    #
    def category_name
      parse_extension_json do |parsing_errors, json|
        if parsing_errors.any?
          ''
        else
          json.fetch('category', '').to_s
        end
      end
    end

    #
    # The metadata specified in the +:tarball+ option's metadata.json entry.
    # May be empty.
    #
    # @return [Metadata]
    #
    def metadata
      parse_tarball_metadata do |parsing_errors, metadata|
        if parsing_errors.any?
          Metadata.new
        else
          metadata
        end
      end
    end

    #
    # The extension's readme. May be empty.
    #
    # @return [Document]
    #
    def readme
      extract_tarball_readme do |extraction_errors, readme|
        if extraction_errors.any?
          Document.new
        else
          readme
        end
      end
    end

    #
    # The extension's changelog. May be empty.
    #
    # @return [Document]
    #
    def changelog
      extract_tarball_changelog do |extraction_errors, changelog|
        if extraction_errors.any?
          Document.new
        else
          changelog
        end
      end
    end

    #
    # Determines if these parameters are valid.
    #
    # @return [TrueClass] if the parameters are valid
    # @return [FalseClass] if the parameters are invalid
    #
    def valid?
      errors.empty?
    end

    #
    # Returns any errors that occurred while parsing the +:extension+ JSON or
    # while parsing the +:tarball+ artifact
    #
    # @return [ActiveModel::Errors]
    #
    def errors
      return @errors if @errors
      error_messages = Set.new.tap do |messages|
        parse_extension_json do |parsing_errors, _|
          parsing_errors.full_messages.each do |message|
            messages << message
          end
        end

        parse_tarball_metadata do |parsing_errors, _|
          parsing_errors.full_messages.each do |message|
            messages << message
          end
        end

        extract_tarball_readme do |extraction_errors, _|
          extraction_errors.full_messages.each do |message|
            messages << message
          end
        end
      end

      @errors = ActiveModel::Errors.new([]).tap do |errors|
        error_messages.each do |error_message|
          errors.add(:base, error_message)
        end
      end
    end

    private

    #
    # Parses the tarball specified by the +:tarball+ option
    #
    # @yieldparam errors [ActiveModel::Errors] any errors that occurred while
    #   parsing and extracting the metadata
    # @yieldparam metadata [Metadata] the resulting metadata
    #
    def parse_tarball_metadata(&block)
      metadata = Metadata.new
      errors = ActiveModel::Errors.new([])

      begin
        path = archive.find(%r{\A(\.\/)?[^\/]+\/metadata\.json\Z}).first

        if path
          metadata = Metadata.new(JSON.parse(archive.read(path)))
        else
          errors.add(:base, I18n.t('api.error_messages.missing_metadata'))
        end
      rescue JSON::ParserError
        errors.add(:base, I18n.t('api.error_messages.metadata_not_json'))
      rescue Virtus::CoercionError
        errors.add(:base, I18n.t('api.error_messages.invalid_metadata'))
      rescue Archive::Error
        errors.add(:base, I18n.t('api.error_messages.tarball_not_gzipped'))
      rescue Archive::NoPath
        errors.add(:base, I18n.t('api.error_messages.tarball_has_no_path'))
      rescue Gem::Package::TarInvalidError => e
        errors.add(:base, I18n.t('api.error_messages.tarball_corrupt', error: e))
      end

      block.call(errors, metadata)
    end

    #
    # Extracts the README from the tarball
    #
    # @yieldparam errors [ActiveModel::Errors] any errors that occurred while
    #   extracting the README
    # @yieldparam readme [Document] the extension's README
    #
    def extract_tarball_readme(&block)
      file_extension = metadata.name
      readme = nil
      errors = ActiveModel::Errors.new([])

      begin
        path = archive.find(%r{\A(\.\/)?#{file_extension}\/readme(\.\w+)?\Z}i).first

        if path
          readme = Document.new(
            contents: archive.read(path),
            file_extension: File.extname(path)[1..-1].to_s
          )

          if readme.contents.blank?
            readme = nil
            errors.add(:base, I18n.t('api.error_messages.missing_readme'))
          end
        else
          errors.add(:base, I18n.t('api.error_messages.missing_readme'))
        end
      rescue Archive::Error
        errors.add(:base, I18n.t('api.error_messages.tarball_not_gzipped'))
      rescue Archive::NoPath
        errors.add(:base, I18n.t('api.error_messages.tarball_has_no_path'))
      rescue Gem::Package::TarInvalidError => e
        errors.add(:base, I18n.t('api.error_messages.tarball_corrupt', error: e))
      end

      block.call(errors, readme)
    end

    #
    # Extracts the CHANGELOG from the tarball
    #
    # @yieldparam errors [ActiveModel::Errors] any errors that occurred while
    #   extracting the CHANGELOG
    # @yieldparam changelog [Document] the extension's CHANGELOG
    #
    def extract_tarball_changelog(&block)
      file_extension = metadata.name
      changelog = nil
      errors = ActiveModel::Errors.new([])

      begin
        path = archive.find(%r{\A(\.\/)?#{file_extension}\/changelog(\.\w+)?\Z}i).first

        if path
          changelog = Document.new(
            contents: archive.read(path),
            file_extension: File.extname(path)[1..-1].to_s
          )
        else
          changelog = Document.new
        end
      rescue Archive::Error
        errors.add(:base, I18n.t('api.error_messages.tarball_not_gzipped'))
      rescue Archive::NoPath
        errors.add(:base, I18n.t('api.error_messages.tarball_has_no_path'))
      end

      block.call(errors, changelog)
    end

    #
    # Parses the JSON string given in the +:extension+ option
    #
    # @yieldparam errors [ActiveModel::Errors] any errors that occurred while
    #   parsing the JSON
    # @yieldparam json [Hash] the deserialized JSON
    #
    def parse_extension_json(&block)
      json = {}
      errors = ActiveModel::Errors.new([])

      begin
        json = JSON.parse(@extension_data)
      rescue JSON::ParserError
        errors.add(:base, I18n.t('api.error_messages.extension_not_json'))
      end

      block.call(errors, json)
    end
  end
end
