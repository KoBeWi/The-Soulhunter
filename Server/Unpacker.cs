using Godot;
using System;
using System.Collections.Generic;
using System.Net.Sockets;

public class Unpacker {
    private string command;
    private byte[] data;
    private int offset = 1;

    public Unpacker(byte[] from) {
        data = from;
        command = GetString();
    }

    public string GetString() {
        int i = offset;
        while (data[i] != 0) i++;

        var initializer = new byte[i - offset];
        Buffer.BlockCopy(data, offset, initializer, 0, i - offset);
        var result = System.Text.Encoding.ASCII.GetString(initializer);

        offset = i+1;

        return result;
    }

    public int GetInt() {
        offset += 2;    
        return data[offset-2] * 256 + data[offset-1];
    }

    public string GetCommand() { return command; }

    public void  HandlePacket(Database database, NetworkStream stream) {
        switch (command) {
            case "REGISTER":
                new Packet("REGISTER").AddInt((int)database.RegisterUser(GetString(), GetString()));

                break;
            case "LOGIN":
                Player player = null;

                var error = database.TryLogin(GetString(), GetString(), stream, out player);

                if (error == Error.Ok) {
                    new Packet("LOGIN").AddInt(0).AddInt(player.GetCharacter().GetMapId()).Send(stream);

                    var room = Server.Instance().GetRoom(player.GetCharacter().GetMapId());
                    room.AddPlayer(player.GetCharacter());
                } else {
                    new Packet("LOGIN").AddInt((int)error).Send(stream);
                }

                break;
        }
    }
}