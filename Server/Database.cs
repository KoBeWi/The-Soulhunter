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
        collection.InsertOne(new BsonDocument {{"login", login}, {"password", password}} );

        return Error.Ok;
    }

    public void Check(string login, string passowrd) {
        var collection = database.GetCollection<BsonDocument>("users");
        collection.Find(new BsonDocument{});
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