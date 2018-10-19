var args = require('minimist') (process.argv.slice(2))
var extend = require('extend')

var environment = args.env || "production"

var common_conf = {
    name: "The Soulhunter game server",
    version: "0.0.1",
    loop_timeout: 5000,
    environment: environment,
    max_players: 100,
    starting_zone: 0,
    client: args.client || "./.client/Client.exe"
}

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