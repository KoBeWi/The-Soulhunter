use crate::util::*;

pub enum Packet {
    Register(String, String),
    Login(String, String),
    GetStats(String),
    KeyPress(u16),
    KeyRelease(u16),
    GetMap,
    Null
}

pub fn parse_packet(buffer: &[u8]) -> Packet {
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