using System;
using System.Collections.Generic;

public class Packet {
    public enum TYPE {
        EMPTY,
        HELLO,
        LOGIN,
        REGISTER,
        ENTER_ROOM,
        KEY_PRESS,
        KEY_RELEASE,
        ADD_ENTITY,
        REMOVE_ENTITY,
        TICK,
        SPECIAL_DATA,
        INITIALIZER,
        CHAT,
        DAMAGE,
        STATS,
        INVENTORY,
        EQUIPMENT,
        SOULS,
        SOUL_EQUIPMENT,
        ABILITIES,
        MAP,
        EQUIP,
        EQUIP_SOUL,
        ITEM_GET,
        SOUL_GET,
        SAVE,
        GAME_OVER
    }

    public static readonly byte[] zero = new byte[] {0};

    private int length;
    private List<byte[]> data;

    public Packet(TYPE command) {
        data = new List<byte[]>();
        length = 1;

        AddU8((byte)command);
    }

    public Packet AddString(string s) {
        data.Add(System.Text.Encoding.ASCII.GetBytes(s));
        data.Add(zero);
        length += s.Length + 1;

        return this;
    }

    public Packet AddStringUnicode(string s) {
        var bytes = System.Text.Encoding.UTF8.GetBytes(s);
        data.Add(bytes);
        data.Add(zero);
        length += bytes.Length + 1;

        return this;
    }

    public Packet AddU8(byte i) {
        data.Add(new byte[] {i});
        length += 1;

        return this;
    }

    public Packet AddU16(ushort i) {
        data.Add(new byte[] {(byte)(i / 256), (byte)(i % 256)});
        length += 2;

        return this;
    }

    public Packet AddU16Array(ushort[] array) {
        AddU8((byte)array.Length);
        foreach (var i in array) AddU16(i);

        return this;
    }

    public Packet AddU32(uint i) {
        data.Add(new byte[] {(byte)(i / 16777216), (byte)(i / 65536), (byte)(i / 256), (byte)(i % 256)});
        length += 4;

        return this;
    }

    public static readonly byte[] boolHelper = {1, 2, 4, 8, 16, 32, 64, 128};

    public Packet AddBoolArray(bool[] bools) {
        byte boolVector = 0;

        for (int i = 0; i < 8; i++) {
            if (i >= bools.Length) break;
            boolVector |= bools[i] ? boolHelper[i] : (byte)0;
        }

        return AddU8(boolVector);
    }

    public Packet AddStateVector(Godot.Collections.Array types, Godot.Collections.Array data, bool[] diffVector) {
        AddBoolArray(diffVector);

        for (int i = 0; i < types.Count; i++) {
            if (!diffVector[i]) continue;

            switch((Data.TYPE)types[i]) {
                case Data.TYPE.U8:
                AddU8((byte)Data.Int(data[i]));
                break;

                case Data.TYPE.U16:
                AddU16((ushort)Data.Int(data[i]));
                break;

                case Data.TYPE.STRING:
                AddString(data[i] as string);
                break;
            }
        }

        return this;
    }

    static readonly string[] statList = {"level", "exp", "hp", "max_hp", "mp", "max_mp", "attack", "defense", "magic_attack", "magic_defense", "luck"};

    public Packet AddStats(Character player, params string[] stats) {
        var vec = new bool[8];
        var vec2 = new bool[8];
        int last_index = -1;

        List<ushort> statsToSend = new List<ushort>();

        foreach(string stat in stats) {
            var index = Array.IndexOf(statList, stat);
            if (index <= last_index) throw new Exception("Wrong order: " + stats);
            last_index = index;

            if (index < 8)
                vec[index] = true;
            else
                vec2[index%8] = true;
            
            statsToSend.Add(player.GetStat(stat));
        }

        AddBoolArray(vec);
        AddBoolArray(vec2);
        foreach (ushort stat in statsToSend) AddU16(stat);

        return this;
    }

    public Packet AddEquipment(ushort[] equipment) {
        bool[] isEq = new bool[8];

        List<ushort> eq = new List<ushort>();

        for (int i = 0; i < equipment.Length; i++) {
            if (equipment[i] > 0) {
                isEq[i] = true;
                eq.Add(equipment[i]);
            }
        }

        AddBoolArray(isEq);
        foreach (var item in eq) { AddU16(item); }

        return this;
    }

    public byte[] Bytes() {
        if (length > 256) {
            Console.WriteLine("Byte limit exceeded: " + length + "\n" + new System.Diagnostics.StackTrace());
            length = 0;
            return new byte[0];
            // throw new Exception("Too many bytes: " + length);
        }

        var bytes = new byte[length];
        bytes[0] = (byte)length;

        int offset = 1;
        foreach (var unit in data) {
            Buffer.BlockCopy(unit, 0, bytes, offset, unit.Length);
            offset += unit.Length;
        }

        return bytes;
    }

    public void Send(System.Net.Sockets.NetworkStream stream) {
        try {
            stream.Write(Bytes(), 0, length);
        } catch (System.IO.IOException) {
            Godot.GD.Print("Sending disrupted");
        }
    }
}