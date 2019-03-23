using System;
using System.Net.Sockets;
using MongoDB.Bson;

public class Player {
    private BsonDocument data;
    private NetworkStream upstream;

    private string login;

    private Character character;

    public Player(BsonDocument _data, NetworkStream stream) {
        data = _data;
        upstream = stream;

        login = data.GetValue("login").AsString;

        character = null;
    }

    public string GetLogin() {return login;}

    public void SetCharacter(string name) {
        character = new Character(this, data);
    }

    public Character GetCharacter() {return character;}

    public void SendPacket(Packet packet) {
        packet.Send(upstream);
    }
}