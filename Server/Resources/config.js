//Import required libraries
var args = require('minimist')(process.argv.slice(2))
var extend = require('extend')

//Store the environment variable
var environment = args.env || "production"

//Common config... ie: name, version, max player etc...
var common_conf = {
    name: "The Soulhunter game server",
    version: "0.0.1",
    environment: environment,
    max_player: 100,
    data_paths: {
        items: __dirname + "/Game Data/Items/",
        maps: __dirname + "/Game Data/Maps/",
        enemies: __dirname + "/Game Data/Enemies/",
        items: __dirname + "/Game Data/Items/",
        souls: __dirname + "/Game Data/Souls/"
    },
    starting_zone: 0,
    client: args.client || __dirname + "/Server-client/Client.exe"
}

//Environment Specific Configuration
var conf = {
    production: {
        ip: args.ip || "0.0.0.0",
        port: args.port || 2412,
        database: "mongodb://127.0.0.1/soulhunter_prod"
    },

    test: {
        ip: args.ip || "0.0.0.0",
        port: args.port || 2413,
        database: "mongodb://127.0.0.1/soulhunter_test"
    }
}

extend(false, conf.production, common_conf)
extend(false, conf.test, common_conf)

module.exports = config = conf[environment]

