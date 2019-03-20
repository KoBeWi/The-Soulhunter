using Godot;
using System;
using MongoDB.Driver;
using MongoDB.Bson;

public class Core : Node
{
    // Declare member variables here. Examples:
    // private int a = 2;
    // private string b = "text";

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        var client = new MongoClient("mongodb://localhost");
        var database = client.GetDatabase("forest_friends");
        var collection = database.GetCollection<BsonDocument>("scores");

        GD.Print(collection);
    }

//  // Called every frame. 'delta' is the elapsed time since the previous frame.
//  public override void _Process(float delta)
//  {
//      
//  }
}
