using Godot;
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

public class Server : Node {
    private TcpListener server;
    private Database database;

    private bool available = true;

    public override void _Ready()
    {
        server = new TcpListener(IPAddress.Parse("127.0.0.1"), 2412);
        database = new Database();
        server.Start();
    }

    public override void _Process(float delta) {
        if (available) {
            available = false;

            server.AcceptTcpClientAsync().ContinueWith((client) => {
                var thread = new System.Threading.Thread(ClientLoop);
                thread.Start(client.Result);
                available = true;
            });
        }
    }

    private void ClientLoop(object _client) {
        var client = _client as TcpClient;

        NetworkStream stream = client.GetStream();
        new Packet().AddString("HELLO").Send(stream);

        var bytes = new byte[256];

        while (true) {
            try {
                stream.Read(bytes, 0, bytes.Length);
            } catch (System.IO.IOException) {
                return;
            }

            var unpacker = new Unpacker(bytes);

            GD.Print("Received packet: " + unpacker.GetCommand());

            switch(unpacker.GetCommand()) {
                case "REGISTER":
                    database.RegisterUser(unpacker.GetString(), unpacker.GetString());

                    new Packet().AddString("REGISTER").AddInt(0).Send(stream);

                    break;
                case "LOGIN":

                    break;
            }      
        }
        
        // client.Close();
    }
}