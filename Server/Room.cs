using Godot;
using System;
using System.Collections.Generic;

public class Room {
    private static readonly PackedScene roomFactory = ResourceLoader.Load("res://Server/Nodes/Room.tscn") as PackedScene;
    private static readonly PackedScene playerFactory = ResourceLoader.Load("res://Nodes/Player.tscn") as PackedScene;

    private Node room;
    private Node playerList;

    private List<Character> players;
    private Dictionary<Character, Node> nodeBindings;
    int lastPlayerId;

    public Room(int id) {
        players = new List<Character>();
        nodeBindings = new Dictionary<Character, Node>();
        lastPlayerId = 0;

        room = roomFactory.Instance();
        room.Set("map", id);
        Server.Instance().AddChild(room);

        playerList = room.GetNode("InGame/Players");
    }

    public void Dispose() {
        Server.Instance().RemoveChild(room);
    }

    public int AddPlayer(Character character) {
        var newPlayer = playerFactory.Instance();
        newPlayer.Set("id", ++lastPlayerId);
        nodeBindings.Add(character, newPlayer);
        playerList.AddChild(newPlayer);

        character.SetRoom(this);

        foreach (var player in players) {
            player.GetPlayer().SendPacket(new Packet("ENTER").AddString(character.GetName()).AddInt(lastPlayerId).AddInt(0));
        }

        players.Add(character);

        return lastPlayerId;
    }

    public void RemovePlayer(Character character) {
        players.Remove(character);
        nodeBindings[character].QueueFree();

        foreach (var player in players) {
            player.GetPlayer().SendPacket(new Packet("EXIT").AddString(character.GetName()));
        }
    }
}