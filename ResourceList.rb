require "json"

items = []

for entry in Dir.entries("Resources/Data/Items") - [".", ".."]
    items.concat JSON.parse(File.readlines("Resources/Data/Items/" + entry).join("\n"))
end

puts items.collect.with_index{|item, i| "%d: %s" % [i, item["name"]]}