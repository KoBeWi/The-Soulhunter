#[macro_use]
extern crate gdnative as godot;
extern crate mongodb;

use mongodb::ThreadedClient;

use std::io::prelude::*;
// use std::net::TcpStream;
use std::net::TcpListener;
use std::thread;

fn to_c_string(s: &str) -> Vec<u8> {
    let mut buffer = Vec::with_capacity(s.len()+2);
    // let len = buffer.capacity() as u8;
    // buffer.push(len);
    
    for c in s.chars() {
        buffer.push(c as u8);
    }

    buffer.push('\0' as u8);
    buffer
}

fn from_c_string(buffer: &[u8], start: u8) -> String {
    let mut s = String::from("");
    
    let mut i = start as usize;
    while buffer[i] != '\0' as u8 {
        s.push_str(&(buffer[i] as char).to_string());
        i += 1;
    }

    s
}

fn get_string(buffer: &[u8], p : &mut u8) -> String {
    let s = from_c_string(buffer, *p);
    *p += s.len() as u8 + 1;
    s
}

enum Packet {
    SRegister(String, String),
    SLogin(String, String),
    SGetStats(String),
    SGetMap,

    CGeneric(String),

    PNull
}

fn parse_packet(buffer: &[u8]) -> Packet {
    let mut p = 1 as u8;
    let command = get_string(buffer, &mut p);
    println!("Parsing: {}", command);

    match command.as_ref() {
        "REGISTER" => Packet::SRegister(get_string(buffer, &mut p), get_string(buffer, &mut p)),
        "LOGIN" => Packet::SLogin(get_string(buffer, &mut p), get_string(buffer, &mut p)),
        "GETSTATS" => Packet::SGetStats(get_string(buffer, &mut p)),
        "GETMAP" => Packet::SGetMap,
        _ => Packet::PNull{}
    }
}

godot_class! {
    class HelloWorld: godot::Node {
        fields {
        }

        setup(_builder) {
        }

        constructor(header) {
            HelloWorld {
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

                        stream.write(to_c_string("HELLO").as_slice()).unwrap();
                        stream.flush().unwrap();

                        loop {
                            let mut buffer = [0; 512];
                            stream.read(&mut buffer).unwrap();

                            let data = parse_packet(&buffer);
                            match data {
                                Packet::SRegister(name, password) => {
                                    // let coll = client.db("soulhunter").collection("users");
                                    // coll.insert_one(doc!{ "title": "Back to the Future" }, None).unwrap();
                                    stream.write(&[&[11u8], to_c_string("REGISTER").as_slice(), &[0u8]].concat()).unwrap();
                                    stream.flush().unwrap();
                                }, Packet::SLogin(name, password) => {
                                    stream.write(&[&[9u8], to_c_string("LOGIN").as_slice(), &[0u8, 0u8]].concat()).unwrap();
                                    stream.flush().unwrap();
                                }, Packet::SGetStats(code) => {
                                    
                                }, Packet::SGetMap => {
                                    
                                }, _ => panic!("Bad packet")
                            }
                        }
                    });
                }
            });
        }
    }
}

fn init(handle: godot::init::InitHandle) {
    HelloWorld::register_class(handle);
}

godot_gdnative_init!();
godot_nativescript_init!(init);
godot_gdnative_terminate!();
