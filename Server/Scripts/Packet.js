var zeroBuffer = Buffer.from('00', 'hex')

module.exports = packet = {
    build: function(params){
        var packetParts = []
        var packetSize = 0

        params.forEach(function(param) {
            var buffer
			
            if(typeof param === 'string'){
                buffer = Buffer.from(param, 'utf8')
                buffer = Buffer.concat([buffer, zeroBuffer], buffer.length + 1)
            } else if (typeof param === 'number'){
                buffer = Buffer.alloc(2)
                buffer.writeUInt16LE(param, 0)
            } else if (typeof param === 'object'){ //inaczej, bo to ma być bufor
                buffer = param
            } else {
                console.log("WARNING: Unknown data type in packet builder: " + (typeof param))
				console.trace()
				return
            }

            packetSize += buffer.length
            packetParts.push(buffer)
        })

        var dataBuffer = Buffer.concat(packetParts, packetSize)

        var size = Buffer.alloc(1)
        size.writeUInt8(dataBuffer.length + 1, 0)

        var finalPacket = Buffer.concat([size, dataBuffer], size.length + dataBuffer.length)

        return finalPacket
    },

    parse: function(c, data){
        var idx = 0

        while( idx < data.length ) {
            var packetSize = data.readUInt8(idx)
            var extractedPacket = Buffer.alloc(packetSize)
            data.copy(extractedPacket, 0, idx, idx + packetSize)

            this.interpret(c, extractedPacket)

            idx += packetSize
        }
    },

    interpret: function(c, datapacket){
		if (datapacket.length == 0) {
			process.stdout.write(".")
			return 
		}//masakra ;_;
		
		try {
			var header = PacketModels.header.parse(datapacket)
		} catch (err) {
			console.log("Error reading packet: " + err)
			return
		}
        console.log("Interpret: " + header.command)

        switch (header.command.toUpperCase()) {
            case "LOGIN":
                var data = PacketModels.login.parse(datapacket)
                User.login(data.username, data.password, function(result, user) {//0 OK 1 not exist 2 wrong password 3 online
                    console.log("Login Result " + result)
					
                    if (!result) {
						playersOnline.push(user.username)
						globalChat.push(c)
                        c.user = user
						
                        c.sendSelf(["LOGIN", 0, c.user.current_room])
						console.log(c.user.current_room)
                        c.enterRoom(c.user.current_room)
                    } else {
                        c.sendSelf(["LOGIN", result])
                    }
                })
                break

            case "REGISTER":
                var data = PacketModels.register.parse(datapacket)
                User.register(data.username, data.password, function(result){
                    c.sendSelf(["REGISTER", result])
                })
                break

            case "POS":
				if (!c.master) return
				
                var data = PacketModels.pos.parse(datapacket)
                c.broadcastRoom(["POS", c.user.username, data.x, data.y, data.direction])
				console.log("New pos: " + data.x + ", " + data.y)
                break

            case "TELLPOS":
				if (!c.master) return
				
                var data = PacketModels.tellpos.parse(datapacket)
                c.sendOther(data.targetuser, ["POS", c.user.username, data.x, data.y, data.direction])
                break

            case "KEYPRESS":
                var data = PacketModels.input.parse(datapacket)
				c.pressedKeys.push(data.key)
                c.broadcastRoom(["KEYPRESS", c.user.username, data.key])
                break

            case "KEYRELEASE":
                var data = PacketModels.input.parse(datapacket)
				c.pressedKeys.splice(c.pressedKeys.indexOf(data.key), 1)
                c.broadcastRoom(["KEYRELEASE", c.user.username, data.key])
                break

            case "CHANGEROOM": //trzeba dodawać pomieszczenie do pakietu, bo może przyjść kilka z tego samego
				if (!c.master) return
				
                var data = PacketModels.changeroom.parse(datapacket)
				var map = RoomManager.prototype.getRoom(data.map)
				var player = map.clients[data.player]
				if (!player) return //tak nie powinno być w sumiu
				var newroom = maps[player.user.current_room].exits[data.direction][data.offset]
				if (newroom == undefined) return //tak też
				console.log("Going to: " + newroom)
				
                player.sendSelf(["CHANGEROOM", newroom])
				
                player.exitRoom()
				player.user.current_room = newroom
				player.user.entrance = [{u: 2, r: 3, d: 0, l: 1}[data.direction], data.offset]
                player.enterRoom(newroom)
                break

            case "DAMAGE":
				if (!c.master) return
				
                var data = PacketModels.damage.parse(datapacket)
				var map = RoomManager.prototype.getRoom(data.map)
				if (data.group == "e") {
					var target = map.clients[data.defender]
					
					if (!map.enemies[data.attacker] || !target) return //tak nie powinno być; może dać loga
					var enemy = enemies[map.enemies[data.attacker].id]
					
					var damage = enemy.attack - target.user.defense
					damage = Math.max(damage, 1)
					target.user.hp -= damage
					
					c.broadcast(map.clients, ["DAMAGE", "p", target.id, damage])
				} else if (data.group == "p") {
					if (!map.enemies[data.defender]) return //sprawdzanie też gracza
					var enemy = enemies[map.enemies[data.defender].id]
					var player = map.clients[data.attacker]
					
					var defense = 0
					if (enemy.defense) defense = enemy.defense
					var damage = player.user.attack - defense
					damage = Math.max(damage, 1)
					
					if (enemy.hp)
						enemy.hp -= damage
					else
						enemy.hp = enemy.max_hp - damage
					
					c.broadcast(map.clients, ["DAMAGE", "e", data.defender, damage])
					
					if (enemy.hp <= 0) {
						player.sendSelf(["EXPERIENCE", enemy.experience])
						enemy.drops.forEach(function(drop) {
							if (Math.random() <= drop.rate) {
								c.broadcast(map.clients, ["DROP", data.defender, drop.id])//do każdego gracza liczone oddzielnie ma być
								c.sendSelf(["DROP", data.defender, drop.id, map.id])
							}
						})
						
						var soulIds = []
						var soulDrop = Math.random()
						enemy.souls.forEach(function(soul) {
							if (soulDrop <= soul.rate)
								soulIds.push(soul.id)
						})
						if (soulIds.length > 0) {
							var soul = soulIds[Math.floor(Math.random() * (soulIds.length-1))]//zwalone prawdopodobieństwo przez pospolite dusze
							player.sendSelf(["SOUL", data.defender, soul])//do każdego gracza liczone oddzielnie ma być / może wysyłać wszystkim, bo efekt
							player.user.soul_inventory.push(soul)
						}
						
						enemy.hp = null//niepotrzebne w instancjach
						c.broadcast(map.clients, ["DEAD", "e", data.defender], true)
						c.sendSelf(["DEAD", "e", data.defender, map.id], true)
						
						player.user.experience += enemy.experience
						while ((player.user.experience - GameLogic.levelExpTotal(player.user.level-1)) >= GameLogic.levelExp(player.user.level)) {
							player.user.level += 1
							player.user.max_hp += 10
							player.user.hp = Math.max(player.user.hp + 10, 0)
							player.user.max_mp += 8
							player.user.mp += 8
							player.user.attack += 1
							player.user.defense += 1
							player.sendSelf(["STATS", 1, player.user.level, player.user.experience, player.user.max_hp, player.user.hp, player.user.max_mp, player.user.mp])
						}
					}
				}
                // console.log(data)
                break
			
			case "GETSTATS":
                var data = PacketModels.getstats.parse(datapacket)
				if (data.code == "1")
					c.sendSelf(["STATS", 1, c.user.level, c.user.experience, c.user.max_hp, Math.max(c.user.hp, 0), c.user.max_mp, c.user.mp])
				else if (data.code == "2")
					c.sendSelf(["STATS", 2, c.user.attack, c.user.defense])
				break
			
			case "GETINVENTORY":
                // var data = PacketModels.getstats.parse(datapacket)
				var amount = Math.min(16, c.user.inventory.length)
				c.sendSelf(["INVENTORY", amount].concat(c.user.inventory.slice(0, amount).map(function(item) {return item.id})))
				break
			
			case "GETEQUIPMENT":
                // var data = PacketModels.getstats.parse(datapacket)
				c.sendSelf(["EQUIPMENT"].concat(GameLogic.equipment_slots.map(function(slot) {item = c.user.equipment[slot]
					return (item != null) ? item.id : 65535})))
				break
			
			case "GOTITEM":
				if (!c.master) return
				
                var data = PacketModels.gotitem.parse(datapacket)
				var map = RoomManager.prototype.getRoom(data.map)
				
				var item = new Types.Item(data.id)
				map.clients[data.player].user.inventory.push(item)
				break
			
			case "EQUIP":
                var data = PacketModels.equip.parse(datapacket)
				var item = c.user.inventory.find(function(item) {return item.id == data.id})
				if (item != undefined) {//też sprawdzanie slotu, czy zgodny typ
					if (c.user.equipment[GameLogic.equipment_slots[data.slot]] != null)
						c.user.inventory.push(c.user.equipment[GameLogic.equipment_slots[data.slot]])
					c.user.equipment[GameLogic.equipment_slots[data.slot]] = item
					c.user.markModified("equipment")
					c.user.inventory.splice(c.user.inventory.indexOf(item), 1)
				}
				break
			
			case "SAVE":
				//if (!c.master) return
				
				c.user.hp = c.user.max_hp
				c.user.mp = c.user.max_mp
				c.user.entrance = [5, 0]
				c.sendSelf(["STATS", 1, c.user.level, c.user.experience, c.user.max_hp, Math.max(c.user.hp, 0), c.user.max_mp, c.user.mp])
				c.user.save() //inaczej, bo lagi
				
				break
			
			case "DISCOVER":
				//if (!c.master) return
				
                var data = PacketModels.discover.parse(datapacket)
				var room = [data.x, data.y] //sprawdzanie, czy poprawne itp.
				
				if (!c.user.map.find(function(room2) {return room[0] == room2[0] && room[1] == room2[1]})) //$addToSet może to zrobić szybciej, ale trzeba wykombinować jak
					c.user.map.push(room)
				
				break
			
			case "GETMAP":
				var amount = Math.min(8, c.user.map.length)
				var map = []
				c.user.map.slice(0, amount).forEach(function(item) {map = map.concat([item[0], item[1]])})
				c.sendSelf(["MAP", amount * 2].concat(map))
				
				break

            case "CHAT":
                var data = PacketModels.chat.parse(datapacket)
				if (data.type == 1)
					c.broadcast(globalChat, ["CHAT", data.type, c.user.username, data.text])
				else if (data.type == 2)
					c.broadcastRoom(["CHAT", data.type, c.user.username, data.text], false, false)
				else if (data.type == 3)
					c.sendOther(data.whisper, ["CHAT", data.type, c.user.username, data.text], globalChat)
				console.log("Chat/" + c.user.username + "/" + data.text) //może typ
                break

            case "SERVER":
                var data = PacketModels.server.parse(datapacket)
				if (RoomManager.prototype.managers.find(function(manager) {return manager.fit(c, data.code)}))
					console.log("RoomManager instance with code " + data.code + " initiated")
                break

            case "ENEMY":
				if (!c.master) return
				
                var data = PacketModels.enemy.parse(datapacket)
				RoomManager.prototype.getRoom(data.map).addEnemy(data.index, data.id)
                break

            case "PRIVSYNC":
				if (!c.master) return
				
                var data = PacketModels.psync.parse(datapacket)
				// console.log(data.data)
				var map = RoomManager.prototype.getRoom(data.map)
				if (map.clients[data.for])
					map.clients[data.for].sendSelf(["SYNC", data.data])
                break

            case "BROADSYNC":
				if (!c.master) return
				
                var data = PacketModels.bsync.parse(datapacket)
				c.broadcast(RoomManager.prototype.getRoom(data.map).clients, ["SYNC", data.data], false, false)
                break

            case "RNG":
				if (!c.master) return
				
                var data = PacketModels.rng.parse(datapacket)
				c.broadcast(RoomManager.prototype.getRoom(data.map).clients, ["RNG", data.type, data.index, data.id, data.value])
        }
    }
}