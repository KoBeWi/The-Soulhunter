// const { exec } = require('child_process')
const { spawn } = require('child_process')

module.exports = RoomManager = function() {
	this.rooms = []
	this.code = (Math.random() + Math.random()).toString(36).substr(2, 8)
	this.managers.push(this)
	
	var serverClient = spawn(config.client, ['-server', '-' + this.code])

	serverClient.stdout.on('data', (data) => {
	  process.stdout.write("<< " + this.code + " >> " + data)
	})

	serverClient.stderr.on('data', (data) => {
	  process.stdout.write("<< " + this.code + " >> " + data)
	})

	serverClient.on('close', (code) => {
	  console.log(`RoomManager closed with code ${code}`)
	})
	
	// exec(config.client + ' -server -' + this.code, (err, stdout, stderr) => {
		// RoomManager.prototype.stdout = stdout
		
		// if (err) {
			// console.log(err)
		// }

		// console.log("OUT ---------------------------------------------------")
		// console.log(`${stdout}`)
		// console.log("ERR ---------------------------------------------------")
		// console.log(`${stderr}`)
		// console.log("-------------------------------------------------------")
	// })
	console.log("Created RoomManager instance with code: " + this.code)
}

RoomManager.prototype.managers = []

RoomManager.prototype.fit = function(client, code) {
	if (code == this.code) {
		this.master = client
		client.master = true
		return true
	}
	
	return false
}

RoomManager.prototype.getRoom = function(id) {
	var found = null
	
	this.managers.find(function(manager) {
		if (room = manager.rooms[id]) {
			found = room
			return true
		}
	})
	
	return found || new Room(id, this.managers[0]) //wybieranie inaczej ofc, tak samo w find
}

RoomManager.prototype.addRoom = function(room) {
	this.rooms[room.id] = room
	room.master = this.master
	this.master.sendSelf(["NEWROOM", room.id])
}

RoomManager.prototype.clean = function() {
	var rooms = this.rooms
	var master = this.master
	
	rooms.forEach(function(room, index) {
		if (room && !room.isActive()) {
			rooms[index] = undefined
			master.sendSelf(["REMROOM", index])
		}
	})
}

RoomManager.prototype.Room = Room = function(id, manager) {
	Object.assign(this, maps[id])
	
	this.id = id
	this.lastID = 0
	this.manager = manager
	this.clients = []
	this.enemies = []
	this.manager.addRoom(this)
	this.start = Date.now()
	
	console.log("Created room " + id + " in RoomManager instance " + manager.code)
}

Room.prototype.isActive = function() {
	var _this = this
	this.clients.forEach(function(client) {
		if (client) {
			_this.start = Date.now()
			return
		}
	})
	
	return (Date.now() - this.start) < 10000 //TODO: stała room timeout w config
}

Room.prototype.getNextID = function() {
	return this.lastID++
}

Room.prototype.addEnemy = function(index, id) {
	var enemy = enemies[id]
	this.enemies[index] = {id: id}
}