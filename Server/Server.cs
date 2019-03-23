using Godot;
using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

public class Server : Node {
    private TcpListener server;
    private Database database;
    private static Server instance;

    private Dictionary<int, List<Room>> rooms;
    private List<Player> playersOnline;

    private bool available = true;

    public override void _Ready()
    {
        instance = this;
        server = new TcpListener(IPAddress.Parse("127.0.0.1"), 2412);
        database = new Database();
        rooms = new Dictionary<int, List<Room>>();
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
        new Packet("HELLO").Send(stream);

        var bytes = new byte[256];

        while (true) {
            try {
                stream.Read(bytes, 0, bytes.Length);
            } catch (System.IO.IOException) {
                return;
            }

            var unpacker = new Unpacker(bytes);

            GD.Print("Received packet: " + unpacker.GetCommand());

            unpacker.HandlePacket(database, stream);
        }
        
        // client.Close();
    }

    public Room GetRoom(int mapId) {
        if (!rooms.ContainsKey(mapId) || rooms[mapId].Count == 0) {
            return CreateRoom(mapId);
        }

        return rooms[mapId][0]; //tutaj wybór fajnego pokoju
    }

    private Room CreateRoom(int mapId) {
        if (!rooms.ContainsKey(mapId)) {
            rooms.Add(mapId, new List<Room>());
        }

        var room = new Room(mapId);
        rooms[mapId].Add(room);

        return room;
    }

    public void AddOnlinePlayer(Player player) {
        playersOnline.Add(player);
    }

    public Player GetPlayerOnline(string login) {
        return playersOnline.Find((player) => player.GetLogin() == login);
    }

    public static Server Instance() {return instance;}
}