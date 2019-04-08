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
            {"max_hp", 120}
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

    public enum Result {SUCCESS, FAILURE}

        /*
        var collection = database.GetCollection<BsonDocument>("users");

        var document = new BsonDocument {
            { "name", "MongoDB" },
            { "type", "Database" },
            { "count", 1 },
            { "info", new BsonDocument
                {
                    { "x", 203 },
                    { "y", 102 }
                }}
        };

        collection.InsertOne(document);*/
}