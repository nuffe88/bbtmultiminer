typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;
#if __CUDA_ARCH__ < 350
#define ROTL32(x,n) (((x) << (n % 32)) | ((x) >> (32 - (n % 32))))
#define ROTR32(x,n) (((x) >> (n % 32)) | ((x) << (32 - (n % 32))))
#else
#define ROTL32(x,n) __funnelshift_l((x), (x), (n))
#define ROTR32(x,n) __funnelshift_r((x), (x), (n))
#endif
#define min(a,b) ((a<b) ? a : b)
#define mul_hi(a, b) __umulhi(a, b)
#define clz(a) __clz(a)
#define popcount(a) __popc(a)

#define DEV_INLINE __device__ __forceinline__
#if (__CUDACC_VER_MAJOR__ > 8)
#define SHFL(x, y, z) __shfl_sync(0xFFFFFFFF, (x), (y), (z))
#else
#define SHFL(x, y, z) __shfl((x), (y), (z))
#endif


#define PROGPOW_LANES           16
#define PROGPOW_REGS            32
#define PROGPOW_DAG_LOADS       4
#define PROGPOW_CACHE_WORDS     4096
#define PROGPOW_CNT_DAG         64
#define PROGPOW_CNT_MATH        20

typedef struct __align__(16) {uint32_t s[PROGPOW_DAG_LOADS];} dag_t;

// Inner loop for prog_seed 4234
__device__ __forceinline__ void progPowLoop(const uint32_t loop,
        uint32_t mix[PROGPOW_REGS],
        const dag_t *g_dag,
        const uint32_t c_dag[PROGPOW_CACHE_WORDS],
        const bool hack_false)
{
dag_t data_dag;
uint32_t offset, data;
const uint32_t lane_id = threadIdx.x & (PROGPOW_LANES-1);
// global load
offset = SHFL(mix[0], loop%PROGPOW_LANES, PROGPOW_LANES);
offset %= PROGPOW_DAG_ELEMENTS;
offset = offset * PROGPOW_LANES + (lane_id ^ loop) % PROGPOW_LANES;
data_dag = g_dag[offset];
// hack to prevent compiler from reordering LD and usage
if (hack_false) __threadfence_block();
// cache load 0
offset = mix[13] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[24] = ROTR32(mix[24], 9) ^ data;
// random math 0
data = mix[24] ^ mix[0];
mix[6] = ROTR32(mix[6], 24) ^ data;
// cache load 1
offset = mix[31] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[0] = (mix[0] * 33) + data;
// random math 1
data = clz(mix[18]) + clz(mix[15]);
mix[19] = ROTL32(mix[19], 19) ^ data;
// cache load 2
offset = mix[18] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[12] = ROTL32(mix[12], 14) ^ data;
// random math 2
data = mix[25] * mix[14];
mix[8] = ROTL32(mix[8], 27) ^ data;
// cache load 3
offset = mix[22] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[7] = ROTL32(mix[7], 17) ^ data;
// random math 3
data = mix[15] * mix[25];
mix[30] = ROTR32(mix[30], 12) ^ data;
// cache load 4
offset = mix[7] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[23] = ROTL32(mix[23], 2) ^ data;
// random math 4
data = popcount(mix[30]) + popcount(mix[0]);
mix[28] = ROTL32(mix[28], 11) ^ data;
// cache load 5
offset = mix[26] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[1] = ROTL32(mix[1], 15) ^ data;
// random math 5
data = mul_hi(mix[18], mix[0]);
mix[21] = (mix[21] ^ data) * 33;
// cache load 6
offset = mix[28] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[26] = (mix[26] * 33) + data;
// random math 6
data = mix[19] & mix[4];
mix[13] = (mix[13] ^ data) * 33;
// cache load 7
offset = mix[11] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[5] = (mix[5] ^ data) * 33;
// random math 7
data = mix[14] | mix[21];
mix[27] = (mix[27] * 33) + data;
// cache load 8
offset = mix[23] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[4] = (mix[4] * 33) + data;
// random math 8
data = mix[17] | mix[19];
mix[20] = ROTR32(mix[20], 18) ^ data;
// cache load 9
offset = mix[0] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[9] = ROTR32(mix[9], 10) ^ data;
// random math 9
data = mix[19] + mix[2];
mix[29] = (mix[29] ^ data) * 33;
// cache load 10
offset = mix[1] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[17] = (mix[17] ^ data) * 33;
// random math 10
data = mix[4] * mix[8];
mix[25] = ROTL32(mix[25], 16) ^ data;
// cache load 11
offset = mix[27] % PROGPOW_CACHE_WORDS;
data = c_dag[offset];
mix[31] = ROTL32(mix[31], 5) ^ data;
// random math 11
data = mul_hi(mix[5], mix[16]);
mix[3] = (mix[3] ^ data) * 33;
// random math 12
data = mix[8] + mix[4];
mix[2] = ROTL32(mix[2], 12) ^ data;
// random math 13
data = mul_hi(mix[4], mix[23]);
mix[22] = ROTR32(mix[22], 3) ^ data;
// random math 14
data = mix[8] | mix[7];
mix[15] = ROTL32(mix[15], 24) ^ data;
// random math 15
data = mix[28] * mix[9];
mix[11] = (mix[11] * 33) + data;
// random math 16
data = mix[22] | mix[29];
mix[10] = (mix[10] * 33) + data;
// random math 17
data = mul_hi(mix[27], mix[13]);
mix[18] = (mix[18] ^ data) * 33;
// random math 18
data = min(mix[7], mix[6]);
mix[14] = ROTL32(mix[14], 15) ^ data;
// random math 19
data = mix[2] + mix[31];
mix[16] = (mix[16] * 33) + data;
// consume global load data
// hack to prevent compiler from reordering LD and usage
if (hack_false) __threadfence_block();
mix[0] = (mix[0] ^ data_dag.s[0]) * 33;
mix[24] = (mix[24] ^ data_dag.s[1]) * 33;
mix[6] = ROTR32(mix[6], 24) ^ data_dag.s[2];
mix[0] = (mix[0] * 33) + data_dag.s[3];
}

#ifndef MAX_SEARCH_RESULTS
#define MAX_SEARCH_RESULTS 4U
#endif

typedef struct {
    uint32_t count;
    struct {
        // One word for gid and 8 for mix hash
        uint32_t gid;
        uint32_t mix[8];
    } result[MAX_SEARCH_RESULTS];
} Search_results;

typedef struct
{
    uint32_t uint32s[32 / sizeof(uint32_t)];
} hash32_t;

// Implementation based on:
// https://github.com/mjosaarinen/tiny_sha3/blob/master/sha3.c


__device__ __constant__ const uint32_t keccakf_rndc[24] = {
    0x00000001, 0x00008082, 0x0000808a, 0x80008000, 0x0000808b, 0x80000001,
    0x80008081, 0x00008009, 0x0000008a, 0x00000088, 0x80008009, 0x8000000a,
    0x8000808b, 0x0000008b, 0x00008089, 0x00008003, 0x00008002, 0x00000080,
    0x0000800a, 0x8000000a, 0x80008081, 0x00008080, 0x80000001, 0x80008008
};

// Implementation of the permutation Keccakf with width 800.
__device__ __forceinline__ void keccak_f800_round(uint32_t st[25], const int r)
{

    const uint32_t keccakf_rotc[24] = {
        1,  3,  6,  10, 15, 21, 28, 36, 45, 55, 2,  14,
        27, 41, 56, 8,  25, 43, 62, 18, 39, 61, 20, 44
    };
    const uint32_t keccakf_piln[24] = {
        10, 7,  11, 17, 18, 3, 5,  16, 8,  21, 24, 4,
        15, 23, 19, 13, 12, 2, 20, 14, 22, 9,  6,  1
    };

    uint32_t t, bc[5];
    // Theta
    for (int i = 0; i < 5; i++)
        bc[i] = st[i] ^ st[i + 5] ^ st[i + 10] ^ st[i + 15] ^ st[i + 20];

    for (int i = 0; i < 5; i++) {
        t = bc[(i + 4) % 5] ^ ROTL32(bc[(i + 1) % 5], 1);
        for (uint32_t j = 0; j < 25; j += 5)
            st[j + i] ^= t;
    }

    // Rho Pi
    t = st[1];
    for (int i = 0; i < 24; i++) {
        uint32_t j = keccakf_piln[i];
        bc[0] = st[j];
        st[j] = ROTL32(t, keccakf_rotc[i]);
        t = bc[0];
    }

    //  Chi
    for (uint32_t j = 0; j < 25; j += 5) {
        for (int i = 0; i < 5; i++)
            bc[i] = st[j + i];
        for (int i = 0; i < 5; i++)
            st[j + i] ^= (~bc[(i + 1) % 5]) & bc[(i + 2) % 5];
    }

    //  Iota
    st[0] ^= keccakf_rndc[r];
}

__device__ __forceinline__ uint32_t cuda_swab32(const uint32_t x)
{
    return __byte_perm(x, x, 0x0123);
}

// Keccak - implemented as a variant of SHAKE
// The width is 800, with a bitrate of 576, a capacity of 224, and no padding
// Only need 64 bits of output for mining
__device__ __noinline__ uint64_t keccak_f800(hash32_t header, uint64_t seed, hash32_t digest)
{
    uint32_t st[25];

    for (int i = 0; i < 25; i++)
        st[i] = 0;
    for (int i = 0; i < 8; i++)
        st[i] = header.uint32s[i];
    st[8] = seed;
    st[9] = seed >> 32;
    for (int i = 0; i < 8; i++)
        st[10+i] = digest.uint32s[i];

    for (int r = 0; r < 21; r++) {
        keccak_f800_round(st, r);
    }
    // last round can be simplified due to partial output
    keccak_f800_round(st, 21);

    // Byte swap so byte 0 of hash is MSB of result
    return (uint64_t)cuda_swab32(st[0]) << 32 | cuda_swab32(st[1]);
}

#define fnv1a(h, d) (h = (uint32_t(h) ^ uint32_t(d)) * uint32_t(0x1000193))

typedef struct {
    uint32_t z, w, jsr, jcong;
} kiss99_t;

// KISS99 is simple, fast, and passes the TestU01 suite
// https://en.wikipedia.org/wiki/KISS_(algorithm)
// http://www.cse.yorku.ca/~oz/marsaglia-rng.html
__device__ __forceinline__ uint32_t kiss99(kiss99_t &st)
{
    st.z = 36969 * (st.z & 65535) + (st.z >> 16);
    st.w = 18000 * (st.w & 65535) + (st.w >> 16);
    uint32_t MWC = ((st.z << 16) + st.w);
    st.jsr ^= (st.jsr << 17);
    st.jsr ^= (st.jsr >> 13);
    st.jsr ^= (st.jsr << 5);
    st.jcong = 69069 * st.jcong + 1234567;
    return ((MWC^st.jcong) + st.jsr);
}

__device__ __forceinline__ void fill_mix(uint64_t seed, uint32_t lane_id, uint32_t mix[PROGPOW_REGS])
{
    // Use FNV to expand the per-warp seed to per-lane
    // Use KISS to expand the per-lane seed to fill mix
    uint32_t fnv_hash = 0x811c9dc5;
    kiss99_t st;
    st.z = fnv1a(fnv_hash, seed);
    st.w = fnv1a(fnv_hash, seed >> 32);
    st.jsr = fnv1a(fnv_hash, lane_id);
    st.jcong = fnv1a(fnv_hash, lane_id);
    #pragma unroll
    for (int i = 0; i < PROGPOW_REGS; i++)
        mix[i] = kiss99(st);
}

__global__ void 
progpow_search(
    uint64_t start_nonce,
    const hash32_t header,
    const uint64_t target,
    const dag_t *g_dag,
    volatile Search_results* g_output,
    bool hack_false
    )
{
    __shared__ uint32_t c_dag[PROGPOW_CACHE_WORDS];
    uint32_t const gid = blockIdx.x * blockDim.x + threadIdx.x;
    uint64_t const nonce = start_nonce + gid;

    const uint32_t lane_id = threadIdx.x & (PROGPOW_LANES - 1);

    // Load the first portion of the DAG into the cache
    for (uint32_t word = threadIdx.x*PROGPOW_DAG_LOADS; word < PROGPOW_CACHE_WORDS; word += blockDim.x*PROGPOW_DAG_LOADS)
    {
        dag_t load = g_dag[word/PROGPOW_DAG_LOADS];
        for(int i=0; i<PROGPOW_DAG_LOADS; i++)
            c_dag[word + i] =  load.s[i];
    }

    hash32_t digest;
    for (int i = 0; i < 8; i++)
        digest.uint32s[i] = 0;
    // keccak(header..nonce)
    uint64_t seed = keccak_f800(header, nonce, digest);

    __syncthreads();

    #pragma unroll 1
    for (uint32_t h = 0; h < PROGPOW_LANES; h++)
    {
        uint32_t mix[PROGPOW_REGS];

        // share the hash's seed across all lanes
        uint64_t hash_seed = SHFL(seed, h, PROGPOW_LANES);
        // initialize mix for all lanes
        fill_mix(hash_seed, lane_id, mix);

        #pragma unroll 1
        for (uint32_t l = 0; l < PROGPOW_CNT_DAG; l++)
            progPowLoop(l, mix, g_dag, c_dag, hack_false);


        // Reduce mix data to a per-lane 32-bit digest
        uint32_t digest_lane = 0x811c9dc5;
        #pragma unroll
        for (int i = 0; i < PROGPOW_REGS; i++)
            fnv1a(digest_lane, mix[i]);

        // Reduce all lanes to a single 256-bit digest
        hash32_t digest_temp;
        #pragma unroll
        for (int i = 0; i < 8; i++)
            digest_temp.uint32s[i] = 0x811c9dc5;

        for (int i = 0; i < PROGPOW_LANES; i += 8)
            #pragma unroll
            for (int j = 0; j < 8; j++)
                fnv1a(digest_temp.uint32s[j], SHFL(digest_lane, i + j, PROGPOW_LANES));

        if (h == lane_id)
            digest = digest_temp;
    }

    // keccak(header .. keccak(header..nonce) .. digest);
    if (keccak_f800(header, seed, digest) >= target)
        return;

    uint32_t index = atomicInc((uint32_t *)&g_output->count, 0xffffffff);
    if (index >= MAX_SEARCH_RESULTS)
        return;

    g_output->result[index].gid = gid;
    #pragma unroll
    for (int i = 0; i < 8; i++)
        g_output->result[index].mix[i] = digest.uint32s[i];
}