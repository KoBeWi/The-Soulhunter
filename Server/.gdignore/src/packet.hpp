#include <PoolArrays.hpp>

#include <vector>
#include <cstring>

using namespace godot;
using namespace std;

struct Packet {
    Packet();

    Packet& string(const char*);
    Packet& number(const uint16_t);

    operator PoolByteArray() const;

    private:
    vector<PoolByteArray> parts;
};