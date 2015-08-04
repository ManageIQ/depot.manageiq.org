json.start @start
json.total @total
json.extensions @extensions do |e|
  json.id e.id
  json.name e.name
  json.description e.description
  json.created_at e.created_at
  json.updated_at e.updated_at
  json.download_count e.download_count
  json.license_name e.license_name
  json.issues_url e.issues_url
  json.github_url e.github_url
  json.download_url download_extension_url(e)
end
