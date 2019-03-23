using MongoDB.Bson;

public class Character {
    string name;

    int level;
    int maxHp;
    int hp;

    int currentMap;

    Player owner;

    public Character(Player _owner, BsonDocument data) {
        owner = _owner;
        name = data.GetValue("login").AsString;
        currentMap = data.GetValue("location").AsInt32;
    }

    public int GetMapId() {return currentMap;}
    public string GetName() {return name;}
    public Player GetPlayer() {return owner;}
}