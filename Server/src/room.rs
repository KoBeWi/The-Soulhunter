use std::collections::HashMap;
use crate::player::*;

pub struct RoomManager {
    pub rooms : HashMap<u32, Vec<Room>>,
}

impl RoomManager {
    pub fn get_room(&self, server : &mut crate::Server, id : u32) {
    }
}

unsafe impl Send for Room {}
unsafe impl Send for RoomManager {}

pub struct Room {
    pub players : Vec<Player>,
    // pub map : godot::Node,
}