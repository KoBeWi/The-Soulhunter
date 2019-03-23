using System;
using System.Collections.Generic;

public class Packet {
    public static readonly byte[] zero = new byte[] {0};

    private int length;
    private List<byte[]> data;

    public Packet(string command) {
        data = new List<byte[]>();
        length = 1;

        AddString(command);
    }

    public Packet AddString(string s) {
        data.Add(System.Text.Encoding.ASCII.GetBytes(s));
        data.Add(zero);
        length += s.Length + 1;

        return this;
    }

    public Packet AddInt(int i) {
        data.Add(new byte[] {(byte)(i / 256), (byte)(i % 256)});
        length += 2;

        return this;
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