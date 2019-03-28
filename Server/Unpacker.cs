using Godot;
using System;
using System.Collections.Generic;
using System.Net.Sockets;

public class Unpacker {
    private Packet.TYPE command;
    private byte[] data;
    private int offset = 1;

    public Unpacker(byte[] from) {
        data = from;
        command = (Packet.TYPE)GetU8();
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

    public int GetU16() {
        offset += 2;
        return data[offset-2] * 256 + data[offset-1];
    }

    public byte GetU8() {
        offset += 1;
        return data[offset-1];
    }

    public int GetCommand() { return (int)command; }

    public void  HandlePacket(Database database, Player player) {
        switch (command) {
            case Packet.TYPE.REGISTER:
            player.SendPacket(new Packet(Packet.TYPE.REGISTER).AddU8((byte)database.RegisterUser(GetString(), GetString())));

            break;
            case Packet.TYPE.LOGIN:
            var error = database.TryLogin(GetString(), GetString(), player);

            if (error == Error.Ok) {
                var room = Server.Instance().GetRoom(player.GetCharacter().GetMapId());

                player.SendPacket(new Packet(Packet.TYPE.LOGIN).AddU8(0));
                    //.AddU16(0).AddU16(player.GetCharacter().GetMapId())
                    //.AddU16(room.AddPlayer(player.GetCharacter())));

                room.AddPlayer(player.GetCharacter());
            } else {
                player.SendPacket(new Packet(Packet.TYPE.LOGIN).AddU8((byte)error));
            }

            break;
            case Packet.TYPE.KEYPRESS:
            var id = player.GetCharacter().GetPlayerId();
            var key = GetU8();

            Server.GetControls().Call("press_key", id, key);
            player.GetCharacter().BroadcastPacket(new Packet(command).AddU16(id).AddU8(key));

            break;
            case Packet.TYPE.KEYRELEASE:
            id = player.GetCharacter().GetPlayerId();
            key = GetU8();

            Server.GetControls().Call("release_key", id, key);
            player.GetCharacter().BroadcastPacket(new Packet(command).AddU16(id).AddU8(key));

            break;
        }
    }
}