#include <unpacker.hpp>

struct ULogin : public Unpacker {
    string login;
    string password;

    ULogin(PoolByteArray data, string command) {
        init(data, command);

        unpack_str(&login);
        unpack_str(&password);
    }

    void take_action(Ref<StreamPeerTCP> peer) {
        cout << this->login << " " << this->password << endl;

        if (Database::get_document(Database::get_collection("users"), "name", login)) {
            peer->put_data(Packet().add_str("LOGIN").add_u16(0).add_u16(0));
        } else {
            peer->put_data(Packet().add_str("LOGIN").add_u16(1).add_u16(0));
        }

        delete this;
    }
};

void Unpacker::unpack(PoolByteArray data, string command, Ref<StreamPeerTCP> peer) {
    Unpacker* unpacker;

    if (command == "LOGIN") {
        unpacker = new ULogin(data, command);
    } else {
        return;
    }

    unpacker->take_action(peer);
}

Unpacker& Unpacker::unpack_str(string* where) {
    *where = Packet::get_str(this->data, this->index);
    this->index += where->length()+1;

    return *this;
}

Unpacker& Unpacker::unpack_u16(uint16_t* where) {
    *where = Packet::get_u16(this->data, this->index);
    this->index += 2;

    return *this;
}

void Unpacker::init(PoolByteArray data, string command) {
    this->data = data;
    this->index = command.length()+1;
}