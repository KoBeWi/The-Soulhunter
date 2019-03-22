using MongoDB.Bson;

public class Character {
    int level;
    int maxHp;
    int hp;

    int currentMap;

    public Character(BsonDocument data) {
        currentMap = data.GetElement("location").Value.AsInt32;
    }

    public int GetMapId() {return currentMap;}
}