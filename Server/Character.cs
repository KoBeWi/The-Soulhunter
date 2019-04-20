using MongoDB.Bson;

public class Character {
    string name;
    ushort playerId;
    Database database;

    int level;
    int maxHp;
    int hp;

    ushort currentMap;
    Room currentRoom;

    Player owner;

    public Character(Player _owner, BsonDocument data, Database databas) {
        owner = _owner;
        name = data.GetValue("login").AsString;
        currentMap = (ushort)data.GetValue("location").AsInt32;
        database = databas;
    }

    public ushort GetMapId() {return currentMap;}
    public string GetName() {return name;}
    public Player GetPlayer() {return owner;}

    public void SetRoom(Room room) {
        currentRoom = room;
    }

    public void RemoveFromRoom() {
        if (currentRoom != null)
            currentRoom.RemovePlayer(this);
    }

    public void SetNewId(ushort id) {playerId = id;}
    public ushort GetPlayerId() {return playerId;}

    public void BroadcastPacket(Packet packet) {
        if (currentRoom != null) {
            currentRoom.BroadcastPacketExcept(packet, this);
        }
    }

    public void AddExperience(int val) {
        var experience = database.GetStat(name, "exp");
        experience += (ushort)val;
        database.SetStat(name, "exp", experience);
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), "exp"));
    }
}