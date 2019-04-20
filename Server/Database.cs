using Godot;
using System;
using System.Net.Sockets;
using MongoDB.Driver;
using MongoDB.Bson;

public class Database {
    private MongoClient client;
    private IMongoDatabase database;

    public Database() {
        client = new MongoClient("mongodb://localhost");
        database = client.GetDatabase("the_soulhunter");
    }

    public Error RegisterUser(string login, string password) {
        var collection = database.GetCollection<BsonDocument>("users");

        if (collection.CountDocuments(new BsonDocument {{"login", login}} ) == 1) {
            return Error.FileAlreadyInUse;
        }

        collection.InsertOne(new BsonDocument {
            {"login", login},
            {"password", password},
            {"location", 0},
            // {"location", new BsonDocument {{"map_id", 0}, {"from", 5}} },
            {"level", 1},
            {"exp", 0},
            {"hp", 120},
            {"max_hp", 120},
            {"mp", 80},
            {"max_mp", 80}
        } );

        return Error.Ok;
    }

    public Error TryLogin(string login, string password, Player player) {
        var collection = database.GetCollection<BsonDocument>("users");
        var found = collection.Find(new BsonDocument {{"login", login}} ).FirstOrDefault();

        if (found == null) {
            return Error.FileNotFound;
        }

        if (Server.GetPlayerOnline(login) != null) {
            return Error.Busy;
        }

        if (found.GetValue("password") != password) {
            return Error.FileNoPermission;
        }

        player.LogIn(found);
        player.SetCharacter("dummy");
        Server.AddOnlinePlayer(player);

        return Error.Ok;
    }

    public ushort GetStat(string login, string stat) {
        var collection = database.GetCollection<BsonDocument>("users");
        var found = collection.Find(new BsonDocument {{"login", login}} ).FirstOrDefault();

        if (found == null) {
            return 0;
        }

        return (ushort)found.GetValue(stat).AsInt32;
    }

    public void SetStat(string login, string stat, ushort value) {
        var collection = database.GetCollection<BsonDocument>("users");
        var found = collection.Find(new BsonDocument {{"login", login}} ).FirstOrDefault();

        if (found != null) {
            var filter = Builders<BsonDocument>.Filter.Empty;
            var update = Builders<BsonDocument>.Update.Set(stat, value);
            collection.UpdateOne(filter, update);
        }
    }
}