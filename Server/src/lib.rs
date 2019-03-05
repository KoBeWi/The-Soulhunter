#[macro_use]
extern crate gdnative as godot;
extern crate mongodb;
#[macro_use]
extern crate bson;

#[macro_use]
mod packet;
mod util;
mod database;
mod player;
mod room;

use packet::*;
use util::*;
use room::*;
use database::*;

use std::sync::Arc;

use mongodb::ThreadedClient;

use std::io::prelude::*;
// use std::net::TcpStream;
use std::net::TcpListener;
use std::thread;

godot_class! {
    class Server: godot::Node {
        fields {
            room_manager : RoomManager,
        }

        setup(_builder) {
        }

        constructor(header) {
            Server {
                header,
                room_manager: RoomManager{
                    rooms: Vec::new(),
                },
            }
        }

        // export fn test(&mut self) -> u8 {
        //     return 32u8;
        // }

        export fn _ready(&mut self) {
            // unsafe {
            //     self.get_owner().get_node(godot::NodePath::from_str("Node")).unwrap().call(godot::GodotString::from_str("test"), &[]);
            // }

            thread::spawn(|| {
                let client = Arc::new(mongodb::Client::connect("localhost", 27017).expect("Failed to initialize database."));

                let listener = TcpListener::bind("127.0.0.1:2412").unwrap();
                println!("Listening for connections...");

                for stream in listener.incoming() {
                    let thread_client = Arc::clone(&client);
                    
                    thread::Builder::new().name("client#".to_string()).spawn(move || { //tutaj thread pool
                        println!("New client connected.");
                        let mut stream = stream.unwrap();

                        let string = to_c_string("HELLO");
                        stream.write(&pack!(string.as_slice())).unwrap();
                        stream.flush().unwrap();

                        loop {
                            let loop_client = Arc::clone(&thread_client);

                            let mut buffer = [0; 512];
                            stream.read(&mut buffer).unwrap();

                            let data = parse_packet(&buffer);
                            match data {
                                Packet::Register(name, password) => {
                                    register_user(&loop_client, &name, &password);

                                    let data1 = to_c_string("REGISTER");
                                    let data2 = u16to8(0);
                                    stream.write(&pack!(data1.as_slice(), &data2)).unwrap();
                                    stream.flush().unwrap();
                                }, Packet::Login(name, password) => {
                                    let data1 = to_c_string("LOGIN");
                                    let data2 = u16to8(0);
                                    let data3 = u16to8(0);
                                    stream.write(&pack!(data1.as_slice(), &data2, &data3)).unwrap();
                                    stream.flush().unwrap();
                                }, Packet::GetStats(code) => {
                                    
                                }, Packet::GetMap => {
                                    
                                }, _ => panic!("Bad packet")
                            }
                        }
                    }).unwrap();
                }
            });
        }
    }
}

fn init(handle: godot::init::InitHandle) {
    Server::register_class(handle);
}

godot_gdnative_init!();
godot_nativescript_init!(init);
godot_gdnative_terminate!();
