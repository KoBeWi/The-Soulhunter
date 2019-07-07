require "json"

puts "ITEMS"

items = []

for entry in Dir.entries("Resources/Data/Items") - [".", ".."]
    items.concat JSON.parse(File.readlines("Resources/Data/Items/" + entry).join("\n"))
end

puts items.collect.with_index{|item, i| "%d: %s" % [i, item["name"]]}

puts "\nMAPS"

maps = []

for entry in Dir.entries("Maps") - [".", ".."]
    id = "0"
    id = File.readlines("Maps/" + entry).find{|line| line.start_with?("mapid")}&.split(" = ")&.last&.chomp || id
    maps << id + ": " + entry
end

puts maps.sort{|map1, map2| map1.split(":").first.to_i <=> map2.split(":").first.to_i}