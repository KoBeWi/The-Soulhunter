using Godot;
using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

public class Server : Node {
    private TcpListener server;

    private Boolean available = true;

    public override void _Ready()
    {
        server = new TcpListener(IPAddress.Parse("127.0.0.1"), 2412);
        server.Start();
    }

    public override void _Process(float delta) {
        if (available) {
            available = false;

            server.AcceptTcpClientAsync().ContinueWith((client) => {
                var thread = new System.Threading.Thread(ClientLoop);
                thread.Start(client);
                available = true;
            });
        }
    }

    private void ClientLoop(object _client) {
        var client = (_client as Task<TcpClient>).Result;

        NetworkStream stream = client.GetStream();
        new Packet().AddString("HELLO").Send(stream);

        Byte[] bytes = new Byte[256];
        String data = null;



        int i;

        // Loop to receive all the data sent by the client.
        while ((i = stream.Read(bytes, 0, bytes.Length)) > 0) {
            GD.Print(bytes[0]);

            return;
            // Translate data bytes to a ASCII string.
            data = System.Text.Encoding.ASCII.GetString(bytes, 0, i);
            Console.WriteLine("Received: {0}", data);
        
            // Process the data sent by the client.
            data = data.ToUpper();

            byte[] msg = System.Text.Encoding.ASCII.GetBytes(data);

            // Send back a response.
            stream.Write(msg, 0, msg.Length);
            Console.WriteLine("Sent: {0}", data);            
        }
            
        // Shutdown and end connection
        client.Close();
    }
}