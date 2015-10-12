atom_feed language: 'en-US' do |feed|
  feed.title 'Extensions'
  feed.updated safe_updated_at(@extensions)

  @extensions.each do |extension|
    feed.entry extension, url: owner_scoped_extension_url(extension) do |entry|
      entry.title extension.name
      entry.content extension_atom_content(extension.latest_extension_version), type: 'html'

      entry.author do |author|
        author.name extension.maintainer
        author.uri user_url(extension.owner)
      end
    end
  end
end
