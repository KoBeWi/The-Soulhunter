require 'JSON'

def get_value(from)
	from.split(/=\s*/).last.delete("\"").chomp
end

ITEMS = []
(Dir.entries("../Serwer/Resources/Game Data/Items") - [".", ".."]).each do |file|
	ITEMS[file.to_i] = File.readlines("../Serwer/Resources/Game Data/Items/" + file)
end

ITEMS.each.with_index do |item, index|
	f = File.new("Resources/Items/#{index}.json", "w")
	f.puts({name: get_value(item[1]), description: get_value(item[2]), type: get_value(item[3]).downcase}.to_json)
	f.close
end

SOULS = []
(Dir.entries("../Serwer/Resources/Game Data/Souls") - [".", ".."]).each do |file|
	SOULS[file.to_i] = File.readlines("../Serwer/Resources/Game Data/Souls/" + file)
end

SOULS.each.with_index do |item, index|
	f = File.new("Resources/Souls/#{index}.json", "w")
	f.puts({name: get_value(item[1]), description: get_value(item[2]), type: get_value(item[3]).downcase}.to_json)
	f.close
end