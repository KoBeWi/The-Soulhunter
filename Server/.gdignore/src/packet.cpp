#include <packet.hpp>

Packet::Packet() {
    PoolByteArray size;
    size.append(0);
    parts.push_back(size);
}

Packet& Packet::add_str(const char* string) {
    int length = strlen(string);

    PoolByteArray array;
    array.resize(length+1);

    for (int i = 0; i < length; i++)
        array.set(i, string[i]);
    
    array.set(length, 0);
    parts.push_back(array);

    return *this;
}

Packet& Packet::add_u16(const uint16_t number) {
    PoolByteArray array;
    array.resize(2);

    array.set(0, number/256);
    array.set(1, number % 256);

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

string Packet::extract_string(PoolByteArray data, int from) {
    stringstream result;

    char c = (char)data[from];
    while (c != '\0') {
        result << c;
        from++;
        c = (char)data[from];
    }

    return result.str();
}