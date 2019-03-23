using Godot;
using System;
using System.Collections.Generic;

public class Room {
    private static readonly PackedScene roomFactory = ResourceLoader.Load("res://Server/Nodes/Room.tscn") as PackedScene;
    private Node room;

    private List<Character> players;

    public Room(int id) {
        players = new List<Character>();

        room = roomFactory.Instance();
        room.Set("map", id);
        Server.Instance().AddChild(room);
    }

    public void Dispose() {
        Server.Instance().RemoveChild(room);
    }

    public void AddPlayer(Character character) {
        character.SetRoom(this);

        foreach (var player in players) {
            player.GetPlayer().SendPacket(new Packet("ENTER").AddString(character.GetName()).AddInt(0).AddInt(0));
        }

        players.Add(character);
    }

    public void RemovePlayer(Character character) {
        players.Remove(character);

        foreach (var player in players) {
            player.GetPlayer().SendPacket(new Packet("EXIT").AddString(character.GetName()));
        }
    }
}