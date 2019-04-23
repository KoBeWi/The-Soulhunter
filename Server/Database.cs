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
        var collection = database.GetCollection<BsonDocument>("players");

        if (collection.CountDocuments(new BsonDocument {{"login", login}} ) == 1) {
            return Error.FileAlreadyInUse;
        }

        collection.InsertOne(new BsonDocument {
            {"login", login},
            {"password", password}
        } );

        return Error.Ok;
    }

    public Error TryLogin(string login, string password, Player player) {
        var collection = database.GetCollection<BsonDocument>("players");
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
        player.SetCharacter(login);
        Server.AddOnlinePlayer(player);

        return Error.Ok;
    }

    public void SetStat(string login, string stat, ushort value) {
        var collection = database.GetCollection<BsonDocument>("players");
        var found = collection.Find(new BsonDocument {{"login", login}} ).FirstOrDefault();

        if (found != null) {
            var filter = Builders<BsonDocument>.Filter.Empty;
            var update = Builders<BsonDocument>.Update.Set(stat, value);
            collection.UpdateOne(filter, update);
        }
    }

    public BsonDocument CreateCharacter(string name) {
        var collection = database.GetCollection<BsonDocument>("characters");

        var data = new BsonDocument {
            {"name", name},
            {"location", 0},
            {"level", 1},
            {"exp", 0},
            {"hp", 120},
            {"max_hp", 120},
            {"mp", 80},
            {"max_mp", 80}
        };

        collection.InsertOne(data);
        return data;
    }

    public Character GetCharacter(string name) {
        var collection = database.GetCollection<BsonDocument>("characters");
        var found = collection.Find(new BsonDocument {{"name", name}} ).FirstOrDefault();

        if (found == null) {
            found = CreateCharacter(name);
        }

        return new Character(found, this); //może powinno trzymać gdzieś instancje
    }
}