using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using Godot;

public class Character {
    private string name;
    private ushort playerId;
    private Database database;
    private BsonDocument data;

    private ushort currentMap;
    private Room currentRoom;

    private Player owner;
    private Node playerNode;

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

    public void SetRoom(Room room) {currentRoom = room;}
    public void SetNode(Node player) {
        playerNode = player;
        playerNode.Call("set_stats", data.ToJson());
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
        SetStat("exp", experience);

        var stats = new List<string>();

        var level = GetStat("level");

        var levelUp = false;
        while (experience >= TotalExpForLevel(level)) {
            level++;
            levelUp = true;
        }
        if (levelUp) {
            stats.Add("level");
            SetStat("level", level);

            SetStat("attack", (ushort)(GetStat("attack")+1));
            SetStat("defense", (ushort)(GetStat("defense")+1));
            SetStat("magic_attack", (ushort)(GetStat("magic_attack")+1));
            SetStat("magic_defense", (ushort)(GetStat("magic_defense")+1));
            SetStat("luck", (ushort)(GetStat("luck")+1));
        }

        stats.Add("exp");
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), stats.ToArray()));
    }

    public ushort GetStat(string stat) {
        return (ushort)data.GetValue(stat).AsInt32;
    }

    public void SetStat(string stat, ushort value) {
        data.SetElement(new BsonElement(stat, value));
    }

    public ushort ExpForLevel(ushort level) {
        return (ushort)(level * 10);
    }
        
    public ushort TotalExpForLevel(ushort level) {
        return (ushort)(level * (level + 1) * 5);
    }

    public void Save() {
        database.SaveCharacter(data);
    }
}