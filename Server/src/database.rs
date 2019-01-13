use mongodb::ThreadedClient;
use mongodb::db::ThreadedDatabase;
use std::sync::Arc;

pub fn register_user(client : &Arc<mongodb::Client> ,name : &str, password : &str) {
    let collection = client.db("my_database").collection("users");
    collection.insert_one(doc!{ "name": name, "password": password}, None).unwrap();
}