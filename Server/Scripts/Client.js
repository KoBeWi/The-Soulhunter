var now = require('performance-now')
var _ = require('underscore')

module.exports = function() {//pewnie dać prototypy na funkcje
    var client = this

    this.initiate = function() {
        client.sendSelf(["HELLO", now().toString()]) //przerobić na niestring
		client.pressedKeys = []

        console.log('client initiated')
    }

    this.enterRoom = function(selected_room) {
		client.map = RoomManager.prototype.getRoom(selected_room)
		client.id = client.map.getNextID()
		
        client.map.clients.forEach(function(otherClient) {
			if (!otherClient) return
            otherClient.sendSelf(client.welcomeData())
            client.sendSelf(otherClient.welcomeData())
        })
		client.map.master.sendSelf(client.masterWelcomeData())
		client.sendSelf(["PLAYERID", client.id])
		
		var entrance = client.user.entrance
        client.sendSelf(["POS", client.id, entrance[0], entrance[1]])
        client.map.master.sendSelf(["POS", client.id, entrance[0], entrance[1], selected_room])

        client.map.clients.splice(client.id, 0, client)
    }

    this.exitRoom = function() {
        client.map.clients[client.id] = undefined
		
        client.map.clients.forEach(function(otherClient) {
			if (!otherClient) return
            otherClient.sendSelf(["EXIT", client.id])
        })
		// console.log(" EXITFROM >>> " + client.map.id) //DEBUG
        client.map.master.sendSelf(["EXIT", client.id, client.map.id])
    }

    this.broadcastRoom = function(data, all = false, tellMaster = true) {
        client.map.clients.forEach(function(otherClient) {
			if (!otherClient) return
            if (all || !client.user || otherClient.user.username != client.user.username) {
                otherClient.sendSelf(data)
            }
        })
		if (tellMaster) client.map.master.sendSelf(data)
    }

    this.broadcast = function(channel, data, all = false) {
        channel.forEach(function(otherClient) {
			if (!otherClient) return
            if( all || !client.user || otherClient.user.username != client.user.username) {
                otherClient.sendSelf(data)
            }
        })
    }

    this.sendOther = function(target, data, channel = client.map.clients) {
        channel.forEach(function(otherClient) {
            if(otherClient.user.username == target) {
                otherClient.sendSelf(data)
				return
            }
        })
    }
    
    this.sendSelf = function(data){
        client.socket.write(packet.build(data))//wielokrotnie to jest robione :/
    }

    this.data = function(data){
        packet.parse(client, data)
    }

    this.error = function(err){
        if (client.map != null && !client.master)
			client.exitRoom()
		if (client.user) {
			client.user.save()
			globalChat.splice(playersOnline.indexOf(client), 1)
			playersOnline.splice(playersOnline.indexOf(client.user.username), 1)
		}
		
        console.log("client error " + err.toString())
    }

    this.end = function(){
        if (client.map != null && !client.master)
			client.exitRoom()
		if (client.user) {
			client.user.save()
			globalChat.splice(playersOnline.indexOf(client), 1)
			playersOnline.splice(playersOnline.indexOf(client.user.username), 1)
		}
		
        console.log("client closed")
    }

    this.welcomeData = function() {
      return ["ENTER", client.user.username, client.id, client.pressedKeys.length].concat(client.pressedKeys)
    }

    this.masterWelcomeData = function() {
      return ["ENTER", client.map.id, client.user.username, client.id, client.pressedKeys.length].concat(client.pressedKeys)
    }
}