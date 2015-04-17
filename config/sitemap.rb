# Set the host name for URL creation
if Rails.env.production?
  SitemapGenerator::Sitemap.default_host = Supermarket::Host.full_url
else
  SitemapGenerator::Sitemap.default_host = 'http://www.example.com'
end

# Disable sitemap task status output when using SitemapGenerator in-code
SitemapGenerator.verbose = false

SitemapGenerator::Sitemap.create do
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.

  User.includes(:github_account).find_each do |user|
    add(user_path(user), lastmod: user.updated_at)
  end

end
