using Godot;
using System;
using System.Linq;
using System.Collections.Generic;

public class Room : Viewport {
    private static readonly PackedScene playerFactory = ResourceLoader.Load("res://Nodes/Player.tscn") as PackedScene;

    private ushort mapId;
    private Node entityRoot;
    private Node map;

    ushort lastEntityId;
    private Dictionary<ushort, Node> entityBindings;
    private Dictionary<ushort, Godot.Collections.Array> stateHistory;
    private List<Node> specialNodes;

    private List<Character> players;
    private Dictionary<Character, Node> playerNodes;

    private byte ticks;
    private uint timeout;

    public override void _Ready() {
        players = new List<Character>();
        entityBindings = new Dictionary<ushort, Node>();
        playerNodes = new Dictionary<Character, Node>();
        stateHistory = new Dictionary<ushort, Godot.Collections.Array>();
        specialNodes = new List<Node>();
        lastEntityId = 0;
        ticks = 0;
        timeout = 0;

        GetNode("InGame").Call("load_map", mapId);
        map = GetNode("InGame/Map");

        entityRoot = GetNode("InGame/Entities");

        GetNode<Timer>("Timer").Connect("timeout", this, "Tick");

        GD.Print("Created new room of map ", mapId);
    }

    public void SetMap(ushort id) { mapId = id; }
    public ushort GetMap() { return mapId; }

    public void Tick() {
        if (players.Count == 0) {
            timeout++;

            if (timeout > 100) {
                GD.Print("Removing room of map ", mapId);
                Server.RemoveRoom(mapId, this);
            }
            return;
        }
        timeout = 0;

        Dictionary<Character, ushort> killUs = new Dictionary<Character, ushort>();

        foreach (var player in playerNodes) {
            var exit = (int)player.Value.Call("check_map", map);
            
            if (exit < 4) {
                Room room = null;
                Vector2 position = (Vector2)player.Value.Get("position");

                if (exit == 1) {
                    room = Server.GetAdjacentMap((int)map.Get("map_x") + (int)map.Get("width"), (int)map.Get("map_y") + (int)position.y / 1080);
                    if (room != null) {
                        position.x -= (int)map.Get("width") * 1920;
                        position.y += ((int)map.Get("map_y") - (int)room.GetMapValue("map_y")) * 1080;
                    }
                } else if (exit == 3) {
                    room = Server.GetAdjacentMap((int)map.Get("map_x") - 1, (int)map.Get("map_y") + (int)position.y / 1080);
                    if (room != null) {
                        position.x += (int)room.GetMapValue("width") * 1920;
                        position.y += ((int)map.Get("map_y") - (int)room.GetMapValue("map_y")) * 1080;
                    }
                }

                if (room != null) {
                    killUs.Add(player.Key, player.Key.GetPlayerId());
                    room.AcquirePlayer(player.Key, player.Value, position);
                }
            }
        }

        foreach (var player in killUs) RemovePlayer(player.Key, false, player.Value);

        var state = CreateStatePacket(false);

        // GD.Print("TICK");
        BroadcastPacket(state);
    }

    private Packet CreateStatePacket(bool full) {
        // var state = new Packet(Packet.TYPE.TICK).AddU32((uint)OS.GetTicksMsec());
        var state = new Packet(Packet.TYPE.TICK).AddU8(ticks++);
        state.AddU8((byte)entityBindings.Count);

        foreach (var id in entityBindings.Keys) {
            var types = entityBindings[id].Call("state_vector_types") as Godot.Collections.Array;
            var data = entityBindings[id].Call("get_state_vector") as Godot.Collections.Array;

            bool[] diffVector;
            if (!full && stateHistory.ContainsKey(id)) {
                diffVector = Data.CompareStateVectors(stateHistory[id], data);
            } else {
                diffVector = new bool[data.Count];
                for (int i = 0; i < diffVector.Length; i++) diffVector[i] = true;
            }
            
            if (!full) {
                stateHistory[id] = data;
            }

            state.AddU16(id);
            state.AddStateVector(types, data, diffVector);
        }

        return state;
    }

    private Packet CreateNodeInitializer(Node node, ushort id) {
        var state = new Packet(Packet.TYPE.INITIALIZER);
        
        var types = node.Call("state_vector_types") as Godot.Collections.Array;
        var data = node.Call("get_state_vector") as Godot.Collections.Array;

        bool[] diffVector = new bool[data.Count];
        for (int i = 0; i < diffVector.Length; i++) diffVector[i] = true;

        state.AddU16(id);
        state.AddStateVector(types, data, diffVector);

        return state;
    }

    public int AddPlayer(Character character) {
        var newPlayer = playerFactory.Instance();
        
        newPlayer.Set("uname", character.GetName());
        newPlayer.Set("position", map.GetNode("SavePoint/PlayerSpot").Get("global_position")); //nie można lepiej?
        newPlayer.SetMeta("map", map);
        newPlayer.Call("start");
        
        playerNodes.Add(character, newPlayer);
        entityRoot.AddChild(newPlayer);
        character.SetNewId(lastEntityId);
        newPlayer.SetMeta("id", lastEntityId);

        character.SetNode(newPlayer);
        character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ENTER_ROOM).AddU16(mapId).AddU16(lastEntityId).AddU8(4).AddU8(0)); //po co to ostatnie?; przedostatnie też mało poczebne

        initializePlayer(character);

        return lastEntityId; //niepotrzebne?
    }

    public void RemovePlayer(Character character, bool free = true, ushort idOverride = 0) {
        if (!players.Contains(character)) return;

        players.Remove(character);
        if (free) {
            playerNodes[character].QueueFree();
        } else {
            // entityList.RemoveChild(playerNodes[character]);
        }
        playerNodes.Remove(character);
        
        DisposeNode(idOverride == 0 ? character.GetPlayerId() : idOverride);
    }

    public void AcquirePlayer(Character character, Node newPlayer, Vector2 position) {
        newPlayer.Set("position", position);
        
        playerNodes.Add(character, newPlayer);
        newPlayer.GetParent().RemoveChild(newPlayer);
        entityRoot.AddChild(newPlayer);

        RegisterNode(newPlayer, (ushort)(int)newPlayer.GetMeta("type"), false);
        character.SetNewId(lastEntityId);
        newPlayer.SetMeta("id", lastEntityId);
        newPlayer.SetMeta("room", this);
        newPlayer.SetMeta("map", map);

        character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ENTER_ROOM).AddU16(mapId).AddU16(lastEntityId).AddU8(5).AddU16((ushort)position.x).AddU16((ushort)position.y).AddU8(0)); //po co to ostatnie?; przedostatnie też mało poczebne

        initializePlayer(character);
    }

    private void initializePlayer(Character character) {
        character.SetRoom(this);

        foreach (var id in entityBindings.Keys) {
            if (id == lastEntityId) continue;

            character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ADD_ENTITY)
                    .AddU16((ushort)(int)entityBindings[id].GetMeta("type"))
                    .AddU16(id));
        }

        foreach (var node in specialNodes) {
            var packet = new Packet(Packet.TYPE.SPECIAL_DATA).AddString(node.GetMeta("id") as string);
            character.GetPlayer().SendPacket(GetSpecialNodeData(packet, node, character));
        }

        players.Add(character);

        character.GetPlayer().SendPacket(CreateStatePacket(true));
    }

    public void BroadcastPacket(Packet packet) { //wywala gdy usunie się gracza podczas wysyłania
        foreach (var player in players) {
            player.GetPlayer().SendPacket(packet);
        }
    }

    public void BroadcastPacketExcept(Packet packet, Character except) {
        foreach (var player in players) {
            if (player != except) player.GetPlayer().SendPacket(packet);
        }
    }

    public void RegisterNode(Node node, ushort type, bool clientOnly) {
        lastEntityId++;
        if (!clientOnly) {
            entityBindings.Add((ushort)lastEntityId, node);
            node.SetMeta("type", type);
            node.SetMeta("id", lastEntityId);
        }

        BroadcastPacket(new Packet(Packet.TYPE.ADD_ENTITY).AddU16(type).AddU16(lastEntityId));
        if (clientOnly) BroadcastPacket(CreateNodeInitializer(node, lastEntityId));
    }

    public void RegisterSpecialNode(Node node) {
        specialNodes.Add(node);
    }

    public Packet GetSpecialNodeData(Packet packet, Node node, Character player) {
        RoomUtility.DATA dataType = (RoomUtility.DATA)(int)(node.Call("get_data"));

        switch (dataType) {
            case RoomUtility.DATA.CHEST:
            return packet.AddU8(RoomUtility.IsChestOpened(player, (string)node.GetMeta("id")) ? (byte)1 : (byte)0);
        }

        return null;
    }

    public void DisposeNode(ushort id) {
        if (entityBindings.ContainsKey(id)) {
            var node = entityBindings[id];
            if (node.HasMeta("enemy")) {
                foreach (object playerId in node.GetMeta("attackers") as Godot.Collections.Array) {
                    var player = GetPlayerById((ushort)(int)Godot.GD.Convert(playerId, Godot.Variant.Type.Int));

                    if (player != null) {
                        player.AddExperience(GetEnemyStat(node, "exp"));
                    }
                }
            }
        }

        entityBindings.Remove(id);
        stateHistory.Remove(id);

        BroadcastPacket(new Packet(Packet.TYPE.REMOVE_ENTITY).AddU16(id));
    }

    public ushort GetEnemyStat(Node enemy, string stat) {
        return (ushort)(int)Godot.GD.Convert((enemy.Get("stats") as Godot.Collections.Dictionary)[stat], Godot.Variant.Type.Int);
    }

    public object GetMapValue(string value) {
        return map.Get(value);
    }

    public Character GetPlayerById(ushort id) {
        foreach (Character player in players)
            if (player.GetPlayerId() == id)
                return player;
        
        return null;
    }

    public void Damage(ushort id, int damage) {
        BroadcastPacket(new Packet(Packet.TYPE.DAMAGE).AddU16(id).AddU16((ushort)(damage + 10000)));
    }

    public void Save(ushort playerId) {
        GetPlayerById(playerId).Save();
    }

    public void ItemGet(ushort playerId, ushort itemId) {
        var character = GetPlayerById(playerId);
        character.AddItem(itemId);
        character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ITEM_GET).AddU16(itemId));
    }

    public void SoulGet(ushort playerId, ushort soulId) {
        var character = GetPlayerById(playerId);
        character.AddSoul(soulId);
        character.GetPlayer().SendPacket(new Packet(Packet.TYPE.SOUL_GET).AddU16(soulId));
    }

    public void Interact(RoomUtility.DATA type, Node node, ushort playerId) {
        switch (type) {
            case RoomUtility.DATA.CHEST:
            RoomUtility.OpenChest(node.GetMeta("id") as string, (ushort)(int)node.Get("item"), GetPlayerById(playerId));
            break;
        }
    }

    public void DiscoverRoom(ushort playerId, Vector2 room) {
        foreach (Character player in players)
            if (player.GetPlayerId() == playerId) {
                player.Discover((int)room.x + " " + (int)room.y);
                return;
            }
    }

    public void GameOver(ushort playerId) {
        var player = GetPlayerById(playerId);
        player.GameOver(Server.GetSeconds());
        player.GetPlayer().SendPacket(new Packet(Packet.TYPE.GAME_OVER).AddU16(player.GetGameOverTime()));
        RemovePlayer(player);
    }
}