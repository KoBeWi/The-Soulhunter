var Parser = require('binary-parser').Parser
var StringOptions = {length: 99, zeroTerminated:true}
var BufferOptions = {readUntil: "eof"}

module.exports = PacketModels = {
    header: new Parser().skip(1)
        .string("command", StringOptions),

    login: new Parser().skip(1)
        .string("command", StringOptions)
        .string("username", StringOptions)
        .string("password", StringOptions),

    register: new Parser().skip(1)
        .string("command", StringOptions)
        .string("username", StringOptions)
        .string("password", StringOptions),

    pos: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("x")
        .uint16le("y")
        .string("direction", StringOptions),

    tellpos: new Parser().skip(1)
        .string("command", StringOptions)
        .string("targetuser", StringOptions)
        .uint16le("x")
        .uint16le("y")
        .string("direction", StringOptions),

    input: new Parser().skip(1)
        .string("command", StringOptions)
        .string("key", StringOptions),

    changeroom: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .uint16le("player")
        .string("direction", StringOptions)
        .uint16le("offset"),

    damage: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .string("group", StringOptions)
        .uint16le("attacker")
        .uint16le("defender")
        .string("type", StringOptions),

    getstats: new Parser().skip(1)
        .string("command", StringOptions)
        .string("code", StringOptions),

    gotitem: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .uint16le("player")
        .uint16le("id"),

    equip: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("slot")
        .uint16le("id"),

    discover: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("x")
        .uint16le("y"),

    chat: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("type")
        .string("whisper", StringOptions)
        .string("text", StringOptions),

    server: new Parser().skip(1)
        .string("command", StringOptions)
        .string("code", StringOptions),
		
    enemy: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .uint16le("index")
        .uint16le("id"),
		
    psync: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .uint16le("for")
        .buffer("data", BufferOptions),
		
    bsync: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .buffer("data", BufferOptions),
		
    rng: new Parser().skip(1)
        .string("command", StringOptions)
        .uint16le("map")
        .string("type", StringOptions)
        .uint16le("index")
        .string("id", StringOptions)
        .uint16le("value")
}