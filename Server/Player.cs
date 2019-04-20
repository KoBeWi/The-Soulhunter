using System;
using System.Net.Sockets;
using MongoDB.Bson;

public class Player {
    private BsonDocument data;
    private NetworkStream upstream;
    private Database database;

    private string login;

    private Character character;

    public Player(NetworkStream stream, Database databas) {
        upstream = stream;
        database = databas;
    }

    public void LogIn(BsonDocument _data) {
        data = _data;

        login = data.GetValue("login").AsString;

        character = null;
    }

    public void LogOut() {
        Server.RemoveOnlinePlayer(this);

        if (character != null) {
            character.RemoveFromRoom();
        }
    }

    public string GetLogin() {return login;}

    public void SetCharacter(string name) {
        character = new Character(this, data, database);
    }

    public Character GetCharacter() {return character;}

    public void SendPacket(Packet packet) {
        packet.Send(upstream);
    }

    public ushort GetStat(string stat) {
        return database.GetStat(login, stat); //można jakieś cache
    }
}