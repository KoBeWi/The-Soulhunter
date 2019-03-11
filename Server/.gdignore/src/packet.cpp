#include <packet.hpp>

Packet::Packet() {
    PoolByteArray size;
    size.append(0);
    parts.push_back(size);
}

Packet& Packet::string(const char* string) {
    int length = strlen(string);

    PoolByteArray array;
    array.resize(length+1);

    for (int i = 0; i < length; i++)
        array.set(i, string[i]);
    
    array.set(length, 0);
    parts.push_back(array);

    return *this;
}

Packet& Packet::number(const uint16_t number) {
    PoolByteArray array;
    array.resize(2);

    array.set(0, number/256);
    array.set(0, number % 256);

    parts.push_back(array);

    return *this;
}

Packet::operator PoolByteArray() const {
    PoolByteArray result;
    int size = 0;

    for (PoolByteArray array : parts) {
        size += array.size();
        result.append_array(array);
    }

    result.set(0, size);
    return result;
}