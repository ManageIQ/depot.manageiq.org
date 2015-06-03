require 'virtus'

class ExtensionUpload
  class Document
    include Virtus.value_object

    #
    # @!attribute [r] contents
    #   @return [String] The text of the Document
    #

    #
    # @!attribute [r] extension
    #   @return [String] The README extension
    #

    values do
      attribute :contents, String
      attribute :file_extension, String, default: ''
    end
  end
end
