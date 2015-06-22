atom_feed language: 'en-US' do |feed|
  feed.title "#{@extension.name} versions"
  feed.updated @extension_versions.max_by(&:updated_at).try(:updated_at)

  @extension_versions.each do |v|
    feed.entry(v, url: extension_version_url(@extension, v)) do |entry|
      entry.title "#{v.extension.name} - v#{v.version}"
      entry.content extension_atom_content(v), type: 'html'
      entry.author do |author|
        author.name v.extension.maintainer
        author.uri user_url(v.extension.owner)
      end
    end
  end
end
