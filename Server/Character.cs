using System;
using System.Linq;
using System.Collections.Generic;
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
        playerNode.Call("set_souls", JsonConvert.SerializeObject(getArray("soul_equipment")));
        playerNode.Call("set_abilities", JsonConvert.SerializeObject(GetAbilities()));
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
    }

    public ushort GetStat(string stat) {
        return finalStats[stat];
    }

    private ushort getStat(string stat) {
        return (ushort)data.GetValue(stat).AsInt32;
    }

    static readonly string[] statList = {"level", "exp", "hp", "max_hp", "mp", "max_mp", "attack", "defense", "magic_attack", "magic_defense", "luck"};

    private void syncStats(params string[] forcedDiff) {
        Dictionary<string, ushort> oldStats = null;
        if (finalStats != null) oldStats = dupStats(finalStats);

        finalStats = new Dictionary<string, ushort>();
        foreach (string stat in statList) {
            finalStats[stat] = getStat(stat);
        }

        var souls = GetSoulEquipment();
        Dictionary<string, object> augmentSoul = null;
        if (souls[2] > 0) augmentSoul = dupData(Server.GetSoul(souls[2]));
        Dictionary<string, object> enchantmentSoul = null;
        if (souls[3] > 0) enchantmentSoul = Server.GetSoul(souls[3]);
        Dictionary<string, object> extensionSoul = null;
        if (souls[4] > 0) extensionSoul = Server.GetSoul(souls[4]);

        Data.ApplyExtensionSoul(augmentSoul, extensionSoul);
        Data.ApplyAugmentSoul(finalStats, augmentSoul);

        foreach (ushort i in GetEquipment()) {
            if (i > 0) {
                var item = dupData(Server.GetItem(i));
                Data.ApplyEnchantmentSoul(item, enchantmentSoul);

                foreach (var stat in statList) {
                    if (item.ContainsKey(stat)) {
                        finalStats[stat] += (ushort)Data.Int(item[stat]);
                    }
                }
            }
        }

        finalStats["hp"] = (ushort)Mathf.Min(finalStats["hp"], finalStats["max_hp"]);
        finalStats["mp"] = (ushort)Mathf.Min(finalStats["mp"], finalStats["max_mp"]);

        if (playerNode != null)
            playerNode.Call("set_stats", JsonConvert.SerializeObject(finalStats));
        
        if (forcedDiff.Length > 0 && forcedDiff[0] == "[NO_SEND]") return;
        
        if (oldStats != null) {
            var diff = new List<string>();
            foreach (var stat in statList) {
                if (oldStats[stat] != finalStats[stat] || forcedDiff.Contains(stat))
                    diff.Add(stat);
            }

            if (diff.Count > 0) GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(this, diff.ToArray()));
        }
    }

    private Dictionary<string, object> dupData(Dictionary<string, object> source) {
        var dup = new Dictionary<string, object>();

        foreach (var key in source.Keys) {
            dup[key] = source[key];
        }

        return dup;
    }

    private Dictionary<string, ushort> dupStats(Dictionary<string, ushort> source) {
        var dup = new Dictionary<string, ushort>();

        foreach (var key in source.Keys) {
            dup[key] = source[key];
        }

        return dup;
    }

    public void SetStat(string stat, ushort value) {
        data.SetElement(new BsonElement(stat, value));
    }

    public void SetStatAndSync(string stat, ushort value) {
        data.SetElement(new BsonElement(stat, value));

        syncStats();
    }

    public ushort ExpForLevel(ushort level) {
        return (ushort)(level * 10);
    }
        
    public ushort TotalExpForLevel(ushort level) {
        return (ushort)(level * (level + 1) * 5);
    }

    public void ConsumeItem(byte idx) {
        var inventory = data.GetValue("inventory").AsBsonArray;
        var item = Server.GetItem(inventory[idx].AsInt32);
        
        if (item["type"] as string == "consumable") {
            foreach (var stat in statList) {
                if (item.ContainsKey(stat)) {
                    SetStat(stat, (ushort)(GetStat(stat) + Data.Int(item[stat])));
                }
            }
        }
        inventory.RemoveAt(idx);

        syncStats();
        owner.SendPacket(new Packet(Packet.TYPE.INVENTORY).AddU16Array(GetInventory()));
    }

    public void EquipItem(byte slot, byte from) {
        var equipment = data.GetValue("equipment").AsBsonArray;
        var inventory = data.GetValue("inventory").AsBsonArray;

        var oldEquip = equipment[slot];

        try {
            if (from < 255) {
                equipment.AsBsonArray[slot] = inventory[from];
                inventory.RemoveAt(from);
            } else {
                equipment.AsBsonArray[slot] = 0;
            }
        } catch (ArgumentOutOfRangeException) {
            Console.WriteLine("Invalid item index: " + from);
            return;
        }

        if (oldEquip > 0) inventory.Add(oldEquip);

        owner.SendPacket(new Packet(Packet.TYPE.INVENTORY).AddU16Array(GetInventory()));
        owner.SendPacket(new Packet(Packet.TYPE.EQUIPMENT).AddEquipment(GetEquipment()));

        syncStats();
        
        playerNode.Call("set_equipment", JsonConvert.SerializeObject(getArray("equipment")));
    }

    public void EquipSoul(byte slot, byte from) {
        if (slot < 0 || slot > 6) return;

        var inventory = data.GetValue("souls").AsBsonArray;
        if (slot != 6) {
            var equipment = data.GetValue("soul_equipment").AsBsonArray;

            var oldEquip = equipment[slot];

            try {
                if (from < 255) {
                    equipment.AsBsonArray[slot] = inventory[from];
                    inventory.RemoveAt(from);
                } else {
                    equipment.AsBsonArray[slot] = 0;
                }
            } catch (ArgumentOutOfRangeException) {
                Console.WriteLine("Invalid soul index: " + from);
                return;
            }

            if (oldEquip > 0) inventory.Add(oldEquip);

            owner.SendPacket(new Packet(Packet.TYPE.SOULS).AddU16Array(owner.GetCharacter().GetSouls()));
            owner.SendPacket(new Packet(Packet.TYPE.SOUL_EQUIPMENT).AddEquipment(owner.GetCharacter().GetSoulEquipment()));

            syncStats();
            
            playerNode.Call("set_souls", JsonConvert.SerializeObject(getArray("soul_equipment")));
        } else {
            ToggleAbility(inventory[from].AsInt32);
        }
    }

    public bool[] GetAbilities() {
        var abilities = getStat("abilities");
        bool[] result = new bool[(int)Data.ABILITIES.MAX];

        for (int i = 0; i < (int)Data.ABILITIES.MAX; i++) {
            if ((abilities & Packet.boolHelper[i]) > 0)
                result[i] = true;
        }

        return result;
    }

    public void Save() {
        SetStat("hp", GetStat("max_hp"));
        SetStat("mp", GetStat("max_mp"));
        syncStats("hp", "mp");
        database.SaveCharacter(data);

        GetPlayer().SendPacket(new Packet(Packet.TYPE.SAVE));
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

        var soul = Server.GetSoul(id);
        if (soul["type"] as string == "ability") {
            foreach (var _soul in souls) if (_soul.AsInt32 == id) return;
            ToggleAbility(id);
        }

        souls.Add(id);
        //tu pewnie też
    }

    public void ToggleAbility(int soulId) {
        var soul = Server.GetSoul(soulId);
        
        if (soul["type"] as string != "ability") {
            Console.WriteLine("Impossible");
            return;
        }
        
        var ability = (int)Mathf.Pow(2, Data.Int(soul["ability"]));
        var stat = (int)getStat("abilities");
        var currentState = stat & ability;
        var reverseState = ~currentState & 0xf;

        if (currentState > 0) {
            SetStat("abilities", (ushort)(stat & reverseState));
        } else {
            SetStat("abilities", (ushort)(stat | ability));
        }

        GetPlayer().SendPacket(new Packet(Packet.TYPE.ABILITIES).AddBoolArray(GetAbilities()));
    }

    public void SyncStat(string stat, ushort value) {
        SetStat(stat, value);
        finalStats[stat] = value;
        GetPlayer().SendPacket(new Packet(Packet.TYPE.STATS).AddStats(this, new string[] {stat}));
    }

    public void GameOver(ushort time, bool init = false) {
        if (!init) data = database.GetCharacterData(this);

        SetStat("game_over", time);
        SetStat("hp", (ushort)data.GetValue("max_hp").AsInt32);
        SetStat("mp", (ushort)data.GetValue("max_mp").AsInt32);
        syncStats(new string[] {"[NO_SEND]"});

        if (!init) {
            currentMap = (ushort)data.GetValue("location").AsInt32;
            database.SaveCharacter(data);
        }
    }

    public ushort GetGameOverTime() {
        return (ushort)Mathf.Max((Data.MAX_GAME_OVER_TIME - (Server.GetSeconds() - getStat("game_over"))), 0);
    }

    public ushort GetHue() {
        return getStat("hue");
    }
}