#ifndef PACKET_H
#define PACKET_H

#include <PoolArrays.hpp>

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
    
    static string get_str(PoolByteArray, int);
    static uint16_t get_u16(PoolByteArray, int);

    private:
    list<PoolByteArray> parts;
};

#endif