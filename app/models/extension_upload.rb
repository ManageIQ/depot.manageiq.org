require 'extension_upload/parameters'

class ExtensionUpload
  #
  # Creates a new +ExtensionUpload+.
  #
  # @param user [User] the user uploading the extension
  # @param params [Hash] the upload parameters
  # @option params [String] :extension a JSON string which contains extension
  #   data.
  # @option params [File] :tarball the extension tarball artifact
  #
  def initialize(user, params)
    @user = user
    @params = Parameters.new(params)
  end

  #
  # Finishes the upload process for this +ExtensionUpload+'s parameters.
  #
  # @yieldparam errors [ActiveModel::Errors] errors which occured while
  #   finishing the upload. May be empty.
  # @yieldparam result [Extension, nil] the extension, if the upload succeeds
  # @yieldparam extension_version [ExtensionVersion, nil] the extension version, if
  #   the upload succeeds
  #
  def finish
    result = nil

    if valid?
      upload_errors = ActiveModel::Errors.new([])

      begin
        extension_version = nil

        result = extension.tap do |book|
          extension_version = book.publish_version!(@params)
        end
      rescue ActiveRecord::RecordNotUnique
        metadata = @params.metadata

        version_not_unique = I18n.t(
          'api.error_messages.version_not_unique',
          name: metadata.name,
          version: metadata.version
        )

        upload_errors.add(:base, version_not_unique)
      rescue ActiveRecord::RecordInvalid => e
        e.record.seriously_all_of_the_errors.each do |message|
          upload_errors.add(:base, message)
        end
      end

      yield upload_errors, result, extension_version if block_given?
    else
      yield errors, result, extension_version if block_given?
    end
  end

  #
  # The extension specified by the uploaded metadata. If no such extension
  # exists, the returned extension will only exist in-memory. The owner
  # is assigned to the user uploading the extension if it's a new extension otherwise
  # the owner will remain unchanged.
  #
  # @return [Extension]
  #
  def extension
    Extension.with_name(@params.metadata.name).first_or_initialize.tap do |book|
      book.name = @params.metadata.name
      book.category = category
      book.owner = @user unless book.persisted?
    end
  end

  private

  def valid?
    errors.empty?
  end

  #
  # Returns any errors with the passed-in parameters.
  #
  # @return [ActiveModel::Errors]
  #
  def errors
    @errors ||= ActiveModel::Errors.new([]).tap do |e|
      @params.errors.full_messages.each do |message|
        e.add(:base, message)
      end

      if category.nil? && @params.category_name.present?
        message = I18n.t(
          'api.error_messages.non_existent_category',
          category_name: @params.category_name
        )

        e.add(:base, message)
      end
    end
  end

  #
  # The category specified by the extension params.
  #
  # @return [Category] if such a category exists
  # @return [NilClass] if no such category exists
  #
  def category
    Category.with_name(@params.category_name).first
  end
end
