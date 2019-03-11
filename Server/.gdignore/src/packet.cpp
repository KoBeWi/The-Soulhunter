#include <packet.hpp>

Packet::Packet() {

}

Packet& Packet::string(const char* string) {
    return *this;
}

Packet& Packet::number(const uint16_t number) {
    return *this;
}

Packet::operator PoolByteArray() const {
    return PoolByteArray();
}