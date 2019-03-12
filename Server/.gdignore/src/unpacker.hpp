#ifndef UNPACKER_H
#define UNPACKER_H

#include <PoolArrays.hpp>
#include <StreamPeerTCP.hpp>

#include <packet.hpp>

// #include <list>
// #include <cstring>
#include <iostream>
// #include <sstream>

// using namespace godot;
using namespace std;

struct Unpacker {
    static void unpack(PoolByteArray, string, Ref<StreamPeerTCP>);

    protected:
    PoolByteArray data;
    size_t index;

    void init(PoolByteArray, string);

    Unpacker& unpack_str(string*);
    Unpacker& unpack_u16(uint16_t*);

    virtual void take_action(Ref<StreamPeerTCP>) = 0;
};

#endif