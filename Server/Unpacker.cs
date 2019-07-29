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

    public string GetStringUnicode() {
        int i = offset;
        while (data[i] != 0) i++;

        var initializer = new byte[i - offset];
        Buffer.BlockCopy(data, offset, initializer, 0, i - offset);
        var result = System.Text.Encoding.UTF8.GetString(initializer);

        offset = i+1;

        return result;
    }

    public ushort GetU16() {
        offset += 2;
        return (ushort)(data[offset-2] * 256 + data[offset-1]);
    }

    public byte GetU8() {
        offset += 1;
        return data[offset-1];
    }

    public Packet.TYPE GetCommand() { return command; }

    public void  HandlePacket(Database database, Player player) {
        switch (command) {
            case Packet.TYPE.REGISTER:
            player.SendPacket(new Packet(command).AddU8((byte)database.RegisterUser(GetString(), GetString(), GetU16())));

            break;
            case Packet.TYPE.LOGIN:
            var error = database.TryLogin(GetString(), GetString(), player);

            if (error == Error.Ok) {
                var gameOver = player.GetCharacter().GetGameOverTime();
                if (gameOver > Server.GetSeconds() + Data.MAX_GAME_OVER_TIME) {
                    gameOver = 0;
                    player.GetCharacter().GameOver(0);
                }

                if (gameOver > 0) {
                    player.SendPacket(new Packet(Packet.TYPE.GAME_OVER).AddU16(gameOver));
                } else {
                    Server.SetupPlayer(player.GetCharacter());
                }
            } else {
                player.SendPacket(new Packet(command).AddU8((byte)error));
            }

            break;
            case Packet.TYPE.LOGOUT:
            player.LogOut();

            break;
            case Packet.TYPE.KEY_PRESS:
            var id = player.GetCharacter().GetPlayerId();
            var key = GetU8();

            Server.GetControls().Call("press_key", id, key);
            player.GetCharacter().BroadcastPacket(new Packet(command).AddU16(id).AddU8(key));

            break;
            case Packet.TYPE.KEY_RELEASE:
            id = player.GetCharacter().GetPlayerId();
            key = GetU8();

            Server.GetControls().Call("release_key", id, key);
            player.GetCharacter().BroadcastPacket(new Packet(command).AddU16(id).AddU8(key));

            break;
            case Packet.TYPE.CHAT:
            var mode = GetU8();
            var message = GetStringUnicode(); //debug
            var packet = new Packet(command).AddU8(mode).AddString(player.GetCharacter().GetName()).AddStringUnicode(message);
            GD.Print(player.GetCharacter().GetName(), ": ", message);
            
            if (mode == (byte)Data.CHATS.GLOBAL) {
                foreach (var otherPlayer in Server.GetPlayers()) {
                    if (otherPlayer != player) otherPlayer.SendPacket(packet);
                }
            } else if (mode == (byte)Data.CHATS.LOCAL) {
                player.GetCharacter().BroadcastPacket(packet);
            } else if (mode == (byte)Data.CHATS.WHISPER) {
               var otherPlayer = Server.GetPlayerOnline(GetString());
               if (otherPlayer != null) otherPlayer.SendPacket(packet);
            }

            break;
            case Packet.TYPE.EQUIP:
            player.GetCharacter().EquipItem(GetU8(), GetU8());

            break;
            case Packet.TYPE.CONSUME:
            player.GetCharacter().ConsumeItem(GetU8());

            break;
            case Packet.TYPE.EQUIP_SOUL:
            player.GetCharacter().EquipSoul(GetU8(), GetU8());

            break;
            case Packet.TYPE.GAME_OVER:
            if (player.GetCharacter().GetGameOverTime() <= 0) {
                Server.SetupPlayer(player.GetCharacter());
            }

            break;
        }
    }
}