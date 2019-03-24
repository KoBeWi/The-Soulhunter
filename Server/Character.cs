using MongoDB.Bson;

public class Character {
    string name;
    int playerId;

    int level;
    int maxHp;
    int hp;

    int currentMap;
    Room currentRoom;

    Player owner;

    public Character(Player _owner, BsonDocument data) {
        owner = _owner;
        name = data.GetValue("login").AsString;
        currentMap = data.GetValue("location").AsInt32;
    }

    public int GetMapId() {return currentMap;}
    public string GetName() {return name;}
    public Player GetPlayer() {return owner;}

    public void SetRoom(Room room) {
        currentRoom = room;
    }

    public void RemoveFromRoom() {
        if (currentRoom != null)
            currentRoom.RemovePlayer(this);
    }

    public void SetNewId(int id) {playerId = id;}
    public int GetPlayerId() {return playerId;}

    public void BroadcastPacket(Packet packet) {
        if (currentRoom != null) {
            currentRoom.BroadcastPacketExcept(packet, this);
        }
    }
}