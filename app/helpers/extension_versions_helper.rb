module ExtensionVersionsHelper
  include MarkdownHelper

  #
  # Encapsulates the logic required to return an updated_at timestamp for an
  # Atom feed, while handling possibly empty collections
  #
  # @param collection [Array<Object>] some collection to be checked
  #
  # @return [ActiveSupport::TimeWithZone] the most recent updated_at, or right
  # now
  #
  def safe_updated_at(collection)
    if collection.present?
      collection.max_by(&:updated_at).updated_at
    else
      Time.zone.now
    end
  end

  #
  # Returns an abbreviated Changelog or a description if no Changelog is
  # available for the given ExtensionVersion, suitable for showing in an Atom
  # feed.
  #
  # @param extension_version [ExtensionVersion]
  #
  # @return [String] the Changelog and/or description
  #
  def extension_atom_content(extension_version)
    if extension_version.changelog.present?
      changelog = render_document(
        extension_version.changelog, extension_version.changelog_extension
      )
      changelog_link = link_to(
        'View Full Changelog',
        extension_version_url(
          extension_version.extension,
          extension_version,
          anchor: 'changelog'
        )
      )
      <<-EOS
        <p>#{extension_version.description}</p>
        #{HTML_Truncator.truncate(changelog, 30, ellipsis: '')}
        <p>#{changelog_link}</p>
      EOS
    else
      extension_version.description
    end
  end
  #
  # Returns the given README +content+ as it should be rendered. If the given
  # +extension+ indicates the README is formatted as Markdown, the +content+ is
  # rendered as such.
  #
  # @param content [String] the Document content
  # @param extension [String] the Document extension
  #
  # @return [String] the Document content ready to be rendered
  #
  def render_document(content, extension, repo_loc = "", version = "")
    doc = begin
      if %w(md mdown markdown).include?(extension.downcase)
        render_markdown(content)
      else
        content
      end
    end.gsub(/src="(?!http)(.+)"/, %(src="https://github.com/#{repo_loc}/raw/#{version}/\\1")).html_safe
  end
end
