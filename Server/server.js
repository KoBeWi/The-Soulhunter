require('./Scripts/Config.js')
require('./Scripts/Packet.js')
var fs = require('fs')
var net = require('net')

var init_files = fs.readdirSync("./Scripts/Initializers")
init_files.forEach(function(initFile) {
    console.log('Loading Initializer: ' + initFile)
    require("./Scripts/Initializers/" + initFile)
})

var model_files = fs.readdirSync("./Scripts/Models")
model_files.forEach(function(modelFile){
    console.log('Loading Model: ' + modelFile)
    require("./Scripts/Models/" + modelFile)
})

var load_resources = (container, name) => {
    let files = fs.readdirSync("./Resources/" + name)
    files.forEach((file) => {
        console.log('Loading (' + name + '): ' + file)
        let data = require("./Resources/" + name + "/" + file)
        data.id = parseInt(file.split(".")[0])
        container[data.id] = data
    })
}

load_resources(maps = {}, "Maps")
load_resources(enemies = {}, "Enemies")
load_resources(items = {}, "Items")
load_resources(souls = {}, "Souls")

playersOnline = [] //to może niefajne -> zrobić Set
globalChat = [] //TYMCZASOWE (zamiast tego obiekty czatów i subskrypcje)
new RoomManager()

var client = new require('./Scripts/Client.js')

net.createServer(function(socket) {
    console.log("socket connected")
    var thisClient = new client()

    thisClient.socket = socket
    thisClient.initiate()

    socket.on('error', thisClient.error)
    socket.on('end', thisClient.end)
    socket.on('data', thisClient.data)
}).listen(config.port)

console.log("Initialize Completed, Server runnng on port: " + config.port + " for environment: " + config.environment)

var loop = function() {
	RoomManager.prototype.managers.forEach(function (manager) {manager.clean()})
	
	setTimeout(loop, config.loop_timeout) //TODO: stała loop timeout w config
}

loop()