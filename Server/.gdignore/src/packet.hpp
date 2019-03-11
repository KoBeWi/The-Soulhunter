#include <PoolArrays.hpp>

using namespace godot;

struct Packet {
    Packet();

    Packet& string(const char*);
    Packet& number(const uint16_t);

    operator PoolByteArray() const;
};