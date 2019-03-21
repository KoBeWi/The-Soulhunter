using System;
using System.Collections.Generic;

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
}