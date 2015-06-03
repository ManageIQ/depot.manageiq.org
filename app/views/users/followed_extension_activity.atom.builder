atom_feed language: 'en-US' do |feed|
  feed.title "#{@user.username}'s Followed Extension Activity"
  feed.updated safe_updated_at(@followed_extension_activity)

  @followed_extension_activity.each do |extension_version|
    feed.entry extension_version, url: extension_version_url(extension_version.extension, extension_version.version) do |entry|
      entry.title t('extension.activity',
                    maintainer: extension_version.extension.maintainer,
                    version: extension_version.version,
                    extension: extension_version.extension.name
                   )
      entry.content extension_atom_content(extension_version), type: 'html'

      entry.author do |author|
        author.name extension_version.extension.maintainer
        author.uri user_url(extension_version.extension.owner)
      end
    end
  end
end
