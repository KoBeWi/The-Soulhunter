#[macro_use]
extern crate gdnative as godot;

use std::io::prelude::*;
// use std::net::TcpStream;
use std::net::TcpListener;
use std::thread;

fn to_c_string(s: &str) -> Vec<u8> {
    let mut buffer = Vec::with_capacity(s.len()+2);
    let len = buffer.capacity() as u8;
    buffer.push(len);
    
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
            thread::spawn(|| {
                let listener = TcpListener::bind("127.0.0.1:2412").unwrap();

                for stream in listener.incoming() {

                    thread::spawn(move || { //tutaj thread pool
                        let mut stream = stream.unwrap();

                        stream.write(to_c_string("HELLO").as_slice()).unwrap();
                        stream.flush().unwrap();

                        loop {
                            let mut buffer = [0; 512];
                            stream.read(&mut buffer).unwrap();

                            let command = from_c_string(&buffer, 1);
                            println!("{}", command);

                            if command.starts_with("LOGIN") {
                                stream.write(to_c_string("LOGIN").as_slice()).unwrap();
                                stream.flush().unwrap();
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
