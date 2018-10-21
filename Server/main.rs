#[macro_use]
extern crate gdnative as godot;

use std::io::prelude::*;
use std::net::TcpStream;
use std::net::TcpListener;
use std::thread;

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
                    let mut stream = stream.unwrap();

                    stream.write(&[7u8, 72u8, 69u8, 76u8, 76u8, 79u8, 0u8]).unwrap();
                    stream.flush().unwrap();
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
