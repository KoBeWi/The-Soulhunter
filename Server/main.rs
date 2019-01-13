#[macro_use]
extern crate gdnative as godot;
extern crate mongodb;

use mongodb::ThreadedClient;

use std::io::prelude::*;
// use std::net::TcpStream;
use std::net::TcpListener;
use std::thread;

fn to_c_string(s: &str) -> Vec<u8> {
    let mut buffer = Vec::with_capacity(s.len()+1);
    
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

fn u16to8(from : u16) -> [u8;2] {
    [(from / 256) as u8, (from % 256) as u8]
}

fn get_string(buffer: &[u8], p : &mut u8) -> String {
    let s = from_c_string(buffer, *p);
    *p += s.len() as u8 + 1;
    s
}

fn get_u16(buffer: &[u8], p : &mut u8) -> u16 {
    let mut u = 0u16;
    u += (buffer[*p as usize] as u16) * 256;
    u += buffer[(*p+1) as usize] as u16;
    *p += 2;
    u
}

enum Packet {
    Register(String, String),
    Login(String, String),
    GetStats(String),
    KeyPress(u16),
    KeyRelease(u16),
    GetMap,
    Null
}

fn parse_packet(buffer: &[u8]) -> Packet {
    let mut p = 1 as u8;
    let command = get_string(buffer, &mut p);
    println!("Parsing: {}", command);

    match command.as_ref() {
        "REGISTER" => Packet::Register(get_string(buffer, &mut p), get_string(buffer, &mut p)),
        "LOGIN" => Packet::Login(get_string(buffer, &mut p), get_string(buffer, &mut p)),
        "GETSTATS" => Packet::GetStats(get_string(buffer, &mut p)),
        "KEYPRESS" => Packet::KeyPress(get_u16(buffer, &mut p)),
        "KEYRELEASE" => Packet::KeyRelease(get_u16(buffer, &mut p)),
        "GETMAP" => Packet::GetMap,
        _ => Packet::Null{}
    }
}

macro_rules! pack {
    ( $( $x:expr ),* ) => {
        {
            let mut temp_vec : Vec<&[u8]> = Vec::new();
            let mut len = 0u8;
            temp_vec.push(&[0u8]);

            $(
                temp_vec.push($x);
                len += $x.len() as u8;
            )*

            let mut array = temp_vec.concat();
            array[0] = len+1;

            array
        }
    };
}

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
