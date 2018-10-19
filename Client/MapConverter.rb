require 'JSON'

def find_room(maps, x, y)
	maps.find{|m| m[:x] <= x and m[:y] <= y and m[:x]+m[:w] > x and m[:y]+m[:h] > y}
end

ENEMIES = []
(Dir.entries("../Serwer/Resources/Game Data/Enemies") - [".", ".."]).each do |file|
	ENEMIES[file.to_i] = File.readlines("../Serwer/Resources/Game Data/Enemies/" + file).first.split(/=\s*/).last.delete("\"").chomp
end

files = Dir.entries("maps") - [".", ".."]
maps = []

files.each do |file|
	lines = File.readlines("maps/" + file)
	x = y = id = 0
	width = height = 0
	location = "World"
	enemy_types = {}
	enemies = {}
	
	line = lines.find{|l| l.include?("map_x")}&.scan(/(\d|-)/).join('')&.to_i
	x = line if line
	line = lines.find{|l| l.include?("map_y")}&.scan(/(\d|-)/).join('')&.to_i
	y = line if line
	line = lines.find{|l| l.include?("width")}&.scan(/(\d|-)/).join('')&.to_i
	width = line if line
	line = lines.find{|l| l.include?("height")}&.scan(/(\d|-)/).join('')&.to_i
	height = line if line
	line = lines.find{|l| l.include?("mapid")}&.scan(/(\d|-)/)&.join('')&.to_i
	mapid = line if line
	line = lines.find{|l| l.include?("location")}&.scan(/"([^>]*)"/)&.last&.first
	location = line if line
	line = lines.select{|l| l.include?("Nodes/Enemies")}
	line.each do |line|
		id = line.scan(/id=([^>]*)/).last.first.to_i
		name = line.scan(/([A-Z | a-z]*).tscn/).last.first
		enemy_types[id] = name
	end
	line = lines.select{|l| l.include?("parent=\"Enemies\"")}
	line.each do |line|
		id = line.scan(/\( ([^>]*) \)/).last.first.to_i
		name = line.scan(/name=\"([A-Z | a-z | 0-9]*)\"/).last.first
		enemies[name] = enemy_types[id]
	end
	
	maps << {name: file.chomp(".tscn"), location: location, x: x, y: y, w: width, h: height, enemies: enemies, mapid: mapid}
end

maps.each do |map|
	output = File.new("../Serwer/Resources/Game Data/Maps/#{map[:mapid].to_s.rjust(4, "0")}.js", 'w')
	
	output.puts("exports.location = \"#{map[:location]}\"")
	output.puts
	
	exits = []
	map[:h].times do |dy|
		if room = find_room(maps, map[:x]-1, map[:y]+dy)
			exits << ["left", dy, room[:mapid]]
		end
		if room = find_room(maps, map[:x]+map[:w], map[:y]+dy)
			exits << ["right", dy, room[:mapid]]
		end
	end
	map[:w].times do |dx|
		if room = find_room(maps, map[:x]+dx, map[:y]-1)
			exits << ["up", dx, room[:mapid]]
		end
		if room = find_room(maps, map[:x]+dx, map[:y]+map[:h])
			exits << ["down", dx, room[:mapid]]
		end
	end
	
	output.puts("exports.exits = {")
	output.puts("	u: {#{exits.select{|e| e.first == "up"}.collect{|e| "#{e[1]}: #{e[2]}"}.join(", ")}},")
	output.puts("	r: {#{exits.select{|e| e.first == "right"}.collect{|e| "#{e[1]}: #{e[2]}"}.join(", ")}},")
	output.puts("	d: {#{exits.select{|e| e.first == "down"}.collect{|e| "#{e[1]}: #{e[2]}"}.join(", ")}},")
	output.puts("	l: {#{exits.select{|e| e.first == "left"}.collect{|e| "#{e[1]}: #{e[2]}"}.join(", ")}}")
	output.puts("}")
	
	output.puts
	output.puts("exports.enemies = {")
	map[:enemies].each_pair do |enemy, type|
		output.puts("	#{enemy}: {id: #{ENEMIES.index(type)}},")
	end
	output.puts("}")
	
	# output.puts
	# output.puts("exports.clients = []")
	
	output.close
end