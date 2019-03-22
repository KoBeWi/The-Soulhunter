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
                if (database.RegisterUser(GetString(), GetString()) == Error.FileAlreadyInUse) {
                    new Packet().AddString("REGISTER").AddInt(1).Send(stream);
                } else {
                    new Packet().AddString("REGISTER").AddInt(0).Send(stream);
                }

                break;
            case "LOGIN":
                Character character = null;

                switch (database.TryLogin(GetString(), GetString(), out character)) {
                    case Error.FileNotFound:
                        new Packet().AddString("LOGIN").AddInt(1).Send(stream);
                        break;
                    case Error.FileNoPermission:
                        new Packet().AddString("LOGIN").AddInt(2).Send(stream);
                        break;
                    case Error.FileAlreadyInUse:
                        new Packet().AddString("LOGIN").AddInt(3).Send(stream);
                        break;
                    default:
                        new Packet().AddString("LOGIN").AddInt(0).AddInt(character.GetMapId()).Send(stream);

                        Server.Instance().CreateRoom(character.GetMapId());

                        break;
                };

                break;
        }
    }
}