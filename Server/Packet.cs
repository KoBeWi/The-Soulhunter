using System;
using System.Collections.Generic;

public class Packet {
    public enum TYPE {
        HELLO,
        LOGIN,
        REGISTER,
        ENTER_ROOM,
        PLAYER_ENTER,
        PLAYER_EXIT,
        KEY_PRESS,
        KEY_RELEASE,
        ADD_ENTITY,
        TICK
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

    static readonly byte[] boolHelper = {1, 2, 4, 8, 16, 32, 64, 128};

    public void AddBoolArray(bool[] bools) {
        byte boolVector = 0;

        for (int i = 0; i < 8; i++) {
            if (i >= bools.Length) break;
            boolVector |= bools[i] ? boolHelper[i] : (byte)0;
        }

        AddU8(boolVector);
    }

    public void AddStateVector(Godot.Collections.Array types, Godot.Collections.Array data, bool[] diffVector) {
        AddBoolArray(diffVector);

        for (int i = 0; i < types.Count; i++) {
            if (!diffVector[i]) continue;

            switch((Data.TYPE)types[i]) {
                case Data.TYPE.U8:
                AddU8((byte)(int)Godot.GD.Convert(data[i], 2));
                break;

                case Data.TYPE.U16:
                AddU16((ushort)(int)Godot.GD.Convert(data[i], 2));
                break;

                case Data.TYPE.STRING:
                AddString(data[i] as string);
                break;
            }
        }
    }

    public byte[] Bytes() {
        if (length > 256) {
            throw new Exception("Too many bytes: " + length);
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
        stream.Write(Bytes(), 0, length);
    }
}