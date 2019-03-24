using Godot;
using System;
using System.Collections.Generic;

public class Room : Viewport {
    private static readonly PackedScene playerFactory = ResourceLoader.Load("res://Nodes/Player.tscn") as PackedScene;

    private int mapId;
    private Node playerList;
    private Node map;

    private List<Character> players;
    private Dictionary<Character, Node> nodeBindings;
    int lastPlayerId;

    public override void _Ready() {
        players = new List<Character>();
        nodeBindings = new Dictionary<Character, Node>();
        lastPlayerId = 0;

        GetNode("InGame").Call("load_map", mapId);
        map = GetNode("InGame/Map");

        playerList = GetNode("InGame/Players");

        GetNode<Timer>("Timer").Connect("timeout", this, "Tick");
    }

    public void SetMap(int id) {
        mapId = id;
    }

    // public void Dispose() {
    //     Server.Instance().RemoveChild(room);
    // }

    public int AddPlayer(Character character) {
        var newPlayer = playerFactory.Instance();
        newPlayer.Set("id", ++lastPlayerId);
        newPlayer.Set("position", map.GetNode("SavePoint/PlayerSpot").Get("global_position"));
        newPlayer.Call("start");
        
        character.SetNewId(lastPlayerId);
        nodeBindings.Add(character, newPlayer);
        playerList.AddChild(newPlayer);

        character.SetRoom(this);
        character.GetPlayer().SendPacket(new Packet("EROOM").AddU16(mapId).AddU16(lastPlayerId).AddU8(4).AddU8(0));

        foreach (var player in players) {
            var pos = (Vector2)nodeBindings[player].Get("position");

            character.GetPlayer().SendPacket(new Packet("ENTER")
                .AddString(player.GetName()).AddU16(player.GetPlayerId())
                .AddU8(5).AddU16((int)pos.x).AddU16((int)pos.y).AddU8(0));
            
            player.GetPlayer().SendPacket(new Packet("ENTER").AddString(character.GetName()).AddU16(lastPlayerId).AddU8(4).AddU8(0));
        }

        players.Add(character);

        return lastPlayerId;
    }

    public void RemovePlayer(Character character) {
        players.Remove(character);
        nodeBindings[character].QueueFree();

        BroadcastPacket(new Packet("EXIT").AddU16(character.GetPlayerId()));
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