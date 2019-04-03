using Godot;
using System;
using System.Collections.Generic;

public class Room : Viewport {
    private static readonly PackedScene playerFactory = ResourceLoader.Load("res://Nodes/Player.tscn") as PackedScene;

    private ushort mapId;
    private Node entityList;
    private Node map;

    ushort lastEntityId;
    private Dictionary<ushort, Node> entityBindings;
    private Dictionary<ushort, Godot.Collections.Array> stateHistory;

    private List<Character> players;
    private Dictionary<Character, Node> playerNodes;

    public override void _Ready() {
        players = new List<Character>();
        entityBindings = new Dictionary<ushort, Node>();
        playerNodes = new Dictionary<Character, Node>();
        stateHistory = new Dictionary<ushort, Godot.Collections.Array>();
        lastEntityId = 0;

        GetNode("InGame").Call("load_map", mapId);
        map = GetNode("InGame/Map");

        entityList = GetNode("InGame/Entities");

        GetNode<Timer>("Timer").Connect("timeout", this, "Tick");

        GD.Print("Created new room of map ", mapId);
    }

    public void SetMap(ushort id) {
        mapId = id;
    }

    // public void Dispose() {
    //     Server.Instance().RemoveChild(room);
    // }

    public int AddPlayer(Character character) {
        var newPlayer = playerFactory.Instance();
        
        newPlayer.Set("uname", character.GetName());
        newPlayer.Set("position", map.GetNode("SavePoint/PlayerSpot").Get("global_position")); //nie można lepiej?
        newPlayer.Call("start");
        
        playerNodes.Add(character, newPlayer);
        entityList.AddChild(newPlayer);
        character.SetNewId(lastEntityId);
        newPlayer.SetMeta("id", lastEntityId);

        character.SetRoom(this);
        character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ENTER_ROOM).AddU16(mapId).AddU16(lastEntityId).AddU8(4).AddU8(0));

        foreach (var id in entityBindings.Keys) {
            if (id == lastEntityId) continue;

            character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ADD_ENTITY)
                    .AddU16((ushort)(int)entityBindings[id].GetMeta("type"))
                    .AddU16(id));
            // player.GetPlayer().SendPacket(new Packet(Packet.TYPE.ADD_ENTITY).AddU16(0).AddU16(lastEntityId));
        }

        players.Add(character);

        return lastEntityId;
    }

    public void RemovePlayer(Character character) {
        players.Remove(character);
        playerNodes[character].QueueFree();
        playerNodes.Remove(character);
        stateHistory.Remove(character.GetPlayerId());
        entityBindings.Remove(character.GetPlayerId()); //jakoś uniwersalniej

        BroadcastPacket(new Packet(Packet.TYPE.PLAYER_EXIT).AddU16(character.GetPlayerId()));
    }

    public void BroadcastPacket(Packet packet) {
        foreach (var player in players) {
            player.GetPlayer().SendPacket(packet);
        }
    }

    public void BroadcastPacketExcept(Packet packet, Character except) {
        foreach (var player in players) {
            if (player != except) player.GetPlayer().SendPacket(packet);
        }
    }

    public void Tick() {
        if (players.Count == 0) return; //tutaj też timeout i wywalanie

        var state = new Packet(Packet.TYPE.TICK);
        state.AddU8((byte)entityBindings.Count);

        foreach (var id in entityBindings.Keys) {
            var types = entityBindings[id].Call("state_vector_types") as Godot.Collections.Array;
            var data = entityBindings[id].Call("get_state_vector") as Godot.Collections.Array;

            bool[] diffVector;
            if (stateHistory.ContainsKey(id)) {
                diffVector = Data.CompareStateVectors(stateHistory[id], data);
            } else {
                diffVector = new bool[data.Count];
                for (int i = 0; i < diffVector.Length; i++) diffVector[i] = true;
            }
            stateHistory[id] = data;

            state.AddU16(id);
            state.AddStateVector(types, data, diffVector);
        }

        BroadcastPacket(state);
    }

    public void RegisterNode(Node node, ushort type) {
        node.SetMeta("type", type);
        entityBindings.Add((ushort)++lastEntityId, node);

        foreach (var character in players) {
            character.GetPlayer().SendPacket(new Packet(Packet.TYPE.ADD_ENTITY).AddU16(type).AddU16(lastEntityId));
        }
    }

    // public void ReverseBroadcastPacket(Action<Character> packetMaker) {
    //     foreach (var player in players) {
    //         packetMaker.Invoke(player);
    //     }
    // }

    // public void InitPlayer(Character character) {
    //     var newPlayer = nodeBindings[character];

    //     ReverseBroadcastPacket((player) => {
    //         if (player != character)
    //             character.GetPlayer().SendPacket(new Packet("ENTER")
    //                 .AddString(player.GetName())
    //                 .AddU16(player.GetPlayerId())
    //                 .AddU16(0));
    //     });

    //     BroadcastPacket(new Packet("POS").AddU16((int)newPlayer.Get("id")).AddU16(4).AddU16(0).AddU16(0));
    // }
}