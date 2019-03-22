using Godot;
using System;
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
            {"location", 0 },
            // {"location", new BsonDocument {{"map_id", 0}, {"from", 5}} },
            {"level", 1},
            {"max_hp", 120}
        } );

        return Error.Ok;
    }

    public Error TryLogin(string login, string password, out Character character) {
        var collection = database.GetCollection<BsonDocument>("users");
        var found = collection.Find(new BsonDocument {{"login", login}} ).FirstOrDefault();

        character = null;

        if (found == null) {
            return Error.FileNotFound;
        }

        if (found.GetValue("password") != password) {
            return Error.FileNoPermission;
        }

        character = new Character(found);

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