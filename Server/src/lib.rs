#[macro_use]
extern crate gdnative as godot;
extern crate mongodb;

#[macro_use]
mod packet;
mod util;

use packet::*;
use util::*;

use mongodb::ThreadedClient;

use std::io::prelude::*;
// use std::net::TcpStream;
use std::net::TcpListener;
use std::thread;

godot_class! {
    class Server: godot::Node {
        fields {
        }

        setup(_builder) {
        }

        constructor(header) {
            Server {
                header,
            }
        }

        export fn _ready(&mut self) {
            let client = mongodb::Client::connect("localhost", 27017).expect("Failed to initialize database.");

            thread::spawn(|| {
                let listener = TcpListener::bind("127.0.0.1:2412").unwrap();

                for stream in listener.incoming() {
                    thread::Builder::new().name("client#".to_string()).spawn(move || { //tutaj thread pool
                        let mut stream = stream.unwrap();

                        let string = to_c_string("HELLO");
                        stream.write(&pack!(string.as_slice())).unwrap();
                        stream.flush().unwrap();

                        loop {
                            let mut buffer = [0; 512];
                            stream.read(&mut buffer).unwrap();

                            let data = parse_packet(&buffer);
                            match data {
                                Packet::Register(name, password) => {
                                    // let collection = client.db("my_database").collection("users");
                                    // collection.insert_one(doc!{ "name": "player1" }, None).unwrap();

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
