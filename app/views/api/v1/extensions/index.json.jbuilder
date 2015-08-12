json.start @start
json.total @total

@extensions.each do |e|
  json.partial! e
end
