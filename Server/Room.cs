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

    public void RemoveRoom() {
        Server.Instance().RemoveChild(room);
    }
}