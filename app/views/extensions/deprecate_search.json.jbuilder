json.items @results do |extension|
  json.extension_name extension.name
  json.extension_maintainer extension.maintainer
  json.extension_description extension.description
  json.extension api_v1_extension_url(extension)
end
