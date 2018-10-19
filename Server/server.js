//Import Required Libraries
require(__dirname + '/Resources/config.js')
var fs = require('fs')
var net = require('net')
require('./packet.js')

var init_files = fs.readdirSync(__dirname + "/Initializers")
init_files.forEach(function(initFile) {
    console.log('Loading Initializer: ' + initFile)
    require(__dirname + "/Initializers/" + initFile)
})

var model_files = fs.readdirSync(__dirname + "/Models")
model_files.forEach(function(modelFile){
    console.log('Loading Model: ' + modelFile)
    require(__dirname + "/Models/" + modelFile)
})

maps = {}
var map_files = fs.readdirSync(config.data_paths.maps)
map_files.forEach(function(file){
    console.log('Loading Map: ' + file)
    var map = require(config.data_paths.maps + file)
	map.id = parseInt(file.split(".")[0])
    maps[map.id] = map
})

enemies = {}
var enemy_files = fs.readdirSync(config.data_paths.enemies)
enemy_files.forEach(function(file){
    console.log('Loading Enemy: ' + file)
    var enemy = require(config.data_paths.enemies + file)
	enemy.id = parseInt(file.split(".")[0])
    enemies[enemy.id] = enemy
})

items = {}
var item_files = fs.readdirSync(config.data_paths.items)
item_files.forEach(function(file){
    console.log('Loading Item: ' + file)
    var item = require(config.data_paths.items + file)
	item.id = parseInt(file.split(".")[0])
    items[item.id] = item
})

souls = {}
var soul_files = fs.readdirSync(config.data_paths.souls)
soul_files.forEach(function(file) {
    console.log('Loading Soul: ' + file)
    var soul = require(config.data_paths.souls + file)
	soul.id = parseInt(file.split(".")[0])
    souls[soul.id] = soul
})

playersOnline = [] //to może niefajne -> zrobić Set
globalChat = [] //TYMCZASOWE (zamiast tego obiekty czatów i subskrypcje)
new RoomManager()

net.createServer(function(socket) {
    console.log("socket connected")
    var c_inst = new require('./client.js')
    var thisClient = new c_inst()

    thisClient.socket = socket
    thisClient.initiate()

    socket.on('error', thisClient.error)
    socket.on('end', thisClient.end)
    socket.on('data', thisClient.data)
}).listen(config.port)

console.log("Initialize Completed, Server runnng on port: " + config.port + " for environment: " + config.environment)

var loop = function() {
	RoomManager.prototype.managers.forEach(function (manager) {manager.clean()})
	
	setTimeout(loop, 5000) //TODO: stała loop timeout w config
}

loop()