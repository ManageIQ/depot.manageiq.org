# Set the host name for URL creation
if Rails.env.production?
  SitemapGenerator::Sitemap.default_host = ManageIQ::Host.full_url
else
  SitemapGenerator::Sitemap.default_host = 'http://www.example.com'
end

# Disable sitemap task status output when using SitemapGenerator in-code
SitemapGenerator.verbose = false

SitemapGenerator::Sitemap.create do
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.

  add(extensions_directory_path)

  Extension.find_each do |extension|
    add(extension_path(extension), lastmod: extension.updated_at, priority: 0.8)
  end

  ExtensionVersion.includes(:extension).find_each do |extension_version|
    begin
      add(extension_version_path(extension_version.extension, extension_version), lastmod: extension_version.updated_at)
    rescue ActionController::UrlGenerationError
      # Ignore cases where we have an extension version with a missing or
      # deleted extension
    end
  end

  User.includes(:github_account).find_each do |user|
    add(user_path(user), lastmod: user.updated_at)
  end
end
