cimport cython
from cpython cimport array
import array

# Helper functions we need

#Rotate bits function
@cython.boundscheck(False)
cdef unsigned int ROTL32(unsigned int x, char r):
    return (x << r) | <int>(<unsigned int>x >> (32 - r)) #similar to >>> in Java

@cython.boundscheck(False)
cdef int fmix32 ( int h ):
    h ^= <int>(<unsigned int>h >> 16) # similar to >>> in Java
    h *= <int>0x85ebca6b
    h ^= <int>(<unsigned int>h >> 13)
    h *= <int>0xc2b2ae35
    h ^= <int>(<unsigned int>h >> 16)
  
    return h


cdef int MurmurHash_PushByte(char b, unsigned int* cur_len, int* _h1, char* data):
    cdef unsigned int _len = cur_len[0]
    
    #store the current byte of input
    data[_len % 4] = b
    cur_len[0] = _len = _len + 1

    cdef int c1 = 0xcc9e2d51
    cdef int c2 = 0x1b873593

    # We will use this as the value of _h1 to dirty for returning to the caller
    cdef int h1_as_if_done
    cdef int k1 = 0
    if _len > 0 and _len % 4 == 0:
        # little endian load order
        k1 = (data[0] & 0xff) | ((data[1] & 0xff) << 8) | ((data[2] & 0xff) << 16) | (data[3] << 24)
        k1 *= c1
        k1 = ROTL32(k1,15)
        k1 *= c2

        _h1[0] = _h1[0] ^ k1
        _h1[0] = ROTL32(_h1[0],13)
        _h1[0] = _h1[0]*5+<int>0xe6546b64
        
        h1_as_if_done = _h1[0]
        # data is out the window now
        data[0] = data[1] = data[2] = data[3] = 0
    else: #Tail case
    
        k1 = (data[0] & 0xff) | ((data[1] & (0xff and _len >= 1) ) << 8) | ((data[2] & (0xff and _len >= 2) ) << 16) | ((data[3] and _len >= 1) << 24)
        h1_as_if_done = _h1[0]

        k1 *= c1
        k1 = ROTL32(k1, 15)
        k1 *= c2
        h1_as_if_done = h1_as_if_done ^ k1
    
    h1_as_if_done = h1_as_if_done ^ <int>_len;

    h1_as_if_done = fmix32(h1_as_if_done);

    return h1_as_if_done;
    
def lzjd_f(char* input_bytes, unsigned int hash_size):
    cdef set s1
    s1 = set()
    
    cdef unsigned int cur_length = 0
    cdef char data[4]
    cdef int state = 0
    cdef int hash = 0
    
    for b in input_bytes:
        hash = MurmurHash_PushByte(b, &cur_length, &state, data)
        if not hash in s1:
            s1.add(hash)
            #Reset state
            cur_length = 0
            data[0] = data[1] = data[2] = data[3] = 0
            state = 0
            

    
    return s1