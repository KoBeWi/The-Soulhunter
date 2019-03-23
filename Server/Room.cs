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
        nodeBindings.Add(character, newPlayer);
        playerList.AddChild(newPlayer);

        character.SetRoom(this);

        BroadcastPacket(new Packet("ENTER").AddString(character.GetName()).AddInt(lastPlayerId).AddInt(0));

        players.Add(character);

        return lastPlayerId;
    }

    public void RemovePlayer(Character character) {
        players.Remove(character);
        nodeBindings[character].QueueFree();

        BroadcastPacket(new Packet("EXIT").AddString(character.GetName()));
    }

    public void BroadcastPacket(Packet packet) {
        foreach (var player in players) {
            player.GetPlayer().SendPacket(packet);
        }
    }

    public void InitPlayer(Character character) {
        var newPlayer = nodeBindings[character];
        newPlayer.Set("position", map.GetNode("SavePoint").Get("position")); //hacky af
        var position = (Vector2)newPlayer.Get("position");

        BroadcastPacket(new Packet("PPOS").AddInt((int)newPlayer.Get("id")).AddInt((int)position.x).AddInt((int)position.y).AddInt(0));
    }
}