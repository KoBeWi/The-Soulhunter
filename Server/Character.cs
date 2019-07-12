using System;
using System.Collections.Generic;
using MongoDB.Driver;
using MongoDB.Bson;
using Godot;
using Newtonsoft.Json;

public class Character : Godot.Object {
    private string name;
    private ushort playerId;
    private Database database;
    private BsonDocument data;

    private ushort currentMap;
    private Room currentRoom;

    private Player owner;
    private Node playerNode;

    private Dictionary<string, ushort> finalStats;

    public Character(BsonDocument dat, Database databas) {
        currentMap = (ushort)dat.GetValue("location").AsInt32;
        name = dat.GetValue("name").AsString;
        data = dat;
        database = databas;
        syncStats();
    }

    public void SetPlayer(Player _owner) {owner = _owner;}

    public ushort GetMapId() {return currentMap;}
    public string GetName() {return name;}
    public Player GetPlayer() {return owner;}

    public void SetRoom(Room room) {
        currentRoom = room;
        currentMap = room.GetMap();
        SetStat("location", currentMap);
    }

    public void SetNode(Node player) {
        playerNode = player;
        playerNode.SetMeta("character", this);
        playerNode.Call("set_stats", JsonConvert.SerializeObject(finalStats));
        playerNode.Call("set_equipment", JsonConvert.SerializeObject(getArray("equipment")));
        playerNode.Call("set_souls", JsonConvert.SerializeObject(getArray("soul_equipment")));
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

            stats.Add("exp");

            SetStat("hp", (ushort)(getStat("hp")+10));
            stats.Add("hp");
            SetStat("max_hp", (ushort)(getStat("max_hp")+10));
            stats.Add("max_hp");
            SetStat("mp", (ushort)(getStat("mp")+5));
            stats.Add("mp");
            SetStat("max_mp", (ushort)(getStat("max_mp")+5));
            stats.Add("max_mp");
            SetStat("attack", (ushort)(getStat("attack")+1));
            stats.Add("attack");
            SetStat("defense", (ushort)(getStat("defense")+1));
            stats.Add("defense");
            SetStat("magic_attack", (ushort)(getStat("magic_attack")+1));
            stats.Add("magic_attack");
            SetStat("magic_defense", (ushort)(getStat("magic_defense")+1));
            stats.Add("magic_defense");
            SetStat("luck", (ushort)(getStat("luck")+1));
            stats.Add("luck");
        } else {
            stats.Add("exp");
        }

        syncStats();
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), stats.ToArray()));
    }

    public ushort GetStat(string stat) {
        return finalStats[stat];
    }

    private ushort getStat(string stat) {
        return (ushort)data.GetValue(stat).AsInt32;
    }

    static readonly string[] statList = {"level", "exp", "hp", "max_hp", "mp", "max_mp", "attack", "defense", "magic_attack", "magic_defense", "luck"};

    private void syncStats() {
        finalStats = new Dictionary<string, ushort>();
        foreach (string stat in statList) {
            finalStats[stat] = getStat(stat);
        }

        foreach (ushort i in GetEquipment()) {
            if (i > 0) {
                var item = Server.GetItem(i);

                foreach (var stat in statList) {
                    if (item.ContainsKey(stat)) {
                        finalStats[stat] += (ushort)(int)Godot.GD.Convert(item[stat], Godot.Variant.Type.Int);
                    }
                }
            }
        }

        if (playerNode != null)
            playerNode.Call("set_stats", JsonConvert.SerializeObject(finalStats));
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

    public void EquipItem(byte slot, byte from) {
        var equipment = data.GetValue("equipment").AsBsonArray;
        var inventory = data.GetValue("inventory").AsBsonArray;

        var oldEquip = equipment[slot];

        if (from < 255) {
            equipment.AsBsonArray[slot] = inventory[from];
            inventory.RemoveAt(from);
        } else {
            equipment.AsBsonArray[slot] = 0;
        }

        if (oldEquip > 0) inventory.Add(oldEquip);

        owner.SendPacket(new Packet(Packet.TYPE.INVENTORY).AddU16Array(GetInventory()));
        owner.SendPacket(new Packet(Packet.TYPE.EQUIPMENT).AddEquipment(GetEquipment()));

        syncStats();
        var stats = new List<string>();
        var item = Server.GetItem(equipment.AsBsonArray[slot].AsInt32);
        foreach (var stat in statList) if (item.ContainsKey(stat)) stats.Add(stat);
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), stats.ToArray()));
        
        playerNode.Call("set_equipment", JsonConvert.SerializeObject(getArray("equipment")));
    }

    public void EquipSoul(byte slot, byte from) {
        var equipment = data.GetValue("soul_equipment").AsBsonArray;
        var inventory = data.GetValue("souls").AsBsonArray;

        var oldEquip = equipment[slot];

        if (from < 255) {
            equipment.AsBsonArray[slot] = inventory[from];
            inventory.RemoveAt(from);
        } else {
            equipment.AsBsonArray[slot] = 0;
        }

        if (oldEquip > 0) inventory.Add(oldEquip);

        owner.SendPacket(new Packet(Packet.TYPE.SOULS).AddU16Array(owner.GetCharacter().GetSouls()));
        owner.SendPacket(new Packet(Packet.TYPE.SOUL_EQUIPMENT).AddEquipment(owner.GetCharacter().GetSoulEquipment()));

        // syncStats();
        // var stats = new List<string>();
        // var item = Server.GetItem(equipment.AsBsonArray[slot].AsInt32);
        // foreach (var stat in statList) if (item.ContainsKey(stat)) stats.Add(stat);
        // GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), stats.ToArray()));
        
        playerNode.Call("set_souls", JsonConvert.SerializeObject(getArray("soul_equipment")));
    }

    public void Save() {
        database.SaveCharacter(data);
    }

    public ushort[] GetInventory() {
        return getArray("inventory");
    }

    public ushort[] GetEquipment() {
        return getArray("equipment");
    }

    public ushort[] GetSouls() {
        return getArray("souls");
    }

    public ushort[] GetSoulEquipment() {
        return getArray("soul_equipment");
    }

    public string[] GetChests() {
        return getStringArray("chests");
    }

    public void SetChestOpened(string id) {
        data.GetValue("chests").AsBsonArray.Add(id);
    }

    public ushort[] GetDiscovered() {
        List<ushort> coords = new List<ushort>();
        foreach (var room in getStringArray("discovered")) {
            var xy = room.Split(" ");
            coords.Add(ushort.Parse(xy[0]));
            coords.Add(ushort.Parse(xy[1]));
        }
        return coords.ToArray();
    }

    public void Discover(string room) {
        var discovered = data.GetValue("discovered").AsBsonArray;
        if (!discovered.Contains(room)) discovered.Add(room);
    }

    private ushort[] getArray(string value) {
        var array = data.GetValue(value).AsBsonArray;
        List<ushort> result = new List<ushort>();

        foreach (var item in array) {
            result.Add((ushort)item.AsInt32);
        }

        return result.ToArray();
    }

    private string[] getStringArray(string value) {
        var array = data.GetValue(value).AsBsonArray;
        List<string> result = new List<string>();

        foreach (var item in array) {
            result.Add(item.AsString);
        }

        return result.ToArray();
    }

    public void AddItem(ushort id) {
        var inventory = data.GetValue("inventory").AsBsonArray;
        inventory.Add(id);
        //chyba trzeba odświeżyć
    }

    public void AddSoul(ushort id) {
        var souls = data.GetValue("souls").AsBsonArray;
        souls.Add(id);
        //tu pewnie też
    }

    public void SyncStat(string stat, ushort value) {
        SetStat(stat, value);
        finalStats[stat] = value;//TODO: wygląda na hack
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(GetPlayer(), new string[] {stat}));
    }
}