#include <bsoncxx/builder/stream/document.hpp>
#include <bsoncxx/json.hpp>
#include <mongocxx/client.hpp>
#include <mongocxx/instance.hpp>

using namespace std;

class Database {
    static Database* instance;

	mongocxx::instance* mongo_instance;
	mongocxx::client* client;
    mongocxx::database db;
    
    Database();

    public:
    static void initialize();

    static mongocxx::collection get_collection(string);
    static bsoncxx::stdx::optional<bsoncxx::document::value> get_document(mongocxx::collection, string, string);
};