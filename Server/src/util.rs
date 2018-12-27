pub fn to_c_string(s: &str) -> Vec<u8> {
    let mut buffer = Vec::with_capacity(s.len()+1);
    
    for c in s.chars() {
        buffer.push(c as u8);
    }

    buffer.push('\0' as u8);
    buffer
}

pub fn from_c_string(buffer: &[u8], start: u8) -> String {
    let mut s = String::from("");
    
    let mut i = start as usize;
    while buffer[i] != '\0' as u8 {
        s.push_str(&(buffer[i] as char).to_string());
        i += 1;
    }

    s
}

pub fn u16to8(from : u16) -> [u8;2] {
    [(from / 256) as u8, (from % 256) as u8]
}

pub fn get_string(buffer: &[u8], p : &mut u8) -> String {
    let s = from_c_string(buffer, *p);
    *p += s.len() as u8 + 1;
    s
}

pub fn get_u16(buffer: &[u8], p : &mut u8) -> u16 {
    let mut u = 0u16;
    u += (buffer[*p as usize] as u16) * 256;
    u += buffer[(*p+1) as usize] as u16;
    *p += 2;
    u
}