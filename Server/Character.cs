using System.Collections.Generic;
using MongoDB.Bson;

public class Character {
    private string name;
    private ushort playerId;
    private Database database;
    private BsonDocument data;

    private ushort currentMap;
    private Room currentRoom;

    private Player owner;

    public Character(BsonDocument dat, Database databas) {
        currentMap = (ushort)dat.GetValue("location").AsInt32;
        name = dat.GetValue("name").AsString;
        data = dat;
        database = databas;
    }

    public void SetPlayer(Player _owner) {owner = _owner;}

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

    public void AddExperience(ushort val) {
        var experience = GetStat("exp");
        experience += val;
        database.SetStat(name, "exp", experience);

        var stats = new List<string>();

        var level = GetStat("level");

        var levelUp = false;
        while (experience >= TotalExpForLevel(level)) {
            Godot.GD.Print(level, " ", experience, " ", TotalExpForLevel(level));
            level++;
            levelUp = true;
        }
        if (levelUp) {
            stats.Add("level");
            database.SetStat(name, "level", level);
        }

        stats.Add("exp");
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), stats.ToArray()));
    }

    public ushort GetStat(string stat) {
        return (ushort)data.GetValue(stat).AsInt32;
    }

    public ushort ExpForLevel(ushort level) {
        return (ushort)(level * 10);
    }
        
    public ushort TotalExpForLevel(ushort level) {
        return (ushort)(level * (level + 1) * 5);
    }
}