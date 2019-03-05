use crate::player::*;

pub struct RoomManager {
    pub rooms : Vec<Room>,
}

pub struct Room {
    pub players : Vec<Player>,
}