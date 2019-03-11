#include <PoolArrays.hpp>

#include <vector>
#include <list>
#include <cstring>
#include <iostream>
#include <sstream>

using namespace godot;
using namespace std;

struct Packet {
    Packet();

    Packet& add_str(const char*);
    Packet& add_u16(const uint16_t);

    operator PoolByteArray() const;
    
    static string extract_string(PoolByteArray, int);

    private:
    vector<PoolByteArray> parts;
};