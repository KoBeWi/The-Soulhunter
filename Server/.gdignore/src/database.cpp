#include <database.hpp>

Database* Database::instance = nullptr;

Database::Database() {
	mongo_instance = new mongocxx::instance{};
	client = new mongocxx::client(mongocxx::uri("mongodb://localhost:27017"));
	db = (*client)["the_soulhunter"];
}

void Database::initialize() {
    if (instance == nullptr) {
        instance = new Database();
    }
}

mongocxx::collection Database::get_collection(string name) {
    return instance->db[name];
}

bsoncxx::stdx::optional<bsoncxx::document::value> get_document(mongocxx::collection collection, string key, string value) {
    return collection.find_one((bsoncxx::builder::stream::document{} << key << value << bsoncxx::builder::stream::finalize).view());
}

/*
	mongocxx::collection coll = db["users"];

	auto builder = bsoncxx::builder::stream::document{};
	bsoncxx::document::value doc_value = builder
	<< "name" << "MongoDB"
	<< "type" << "database"
	<< "count" << 1
	<< "versions" << bsoncxx::builder::stream::open_array
		<< "v3.2" << "v3.0" << "v2.6"
	<< bsoncxx::builder::stream::close_array
	<< "info" << bsoncxx::builder::stream::open_document
		<< "x" << 203
		<< "y" << 102
	<< bsoncxx::builder::stream::close_document
	<< bsoncxx::builder::stream::finalize;

	coll.insert_one(doc_value.view());
*/