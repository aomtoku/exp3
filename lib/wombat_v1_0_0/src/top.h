#include "ap_int.h"
#include "hls_stream.h"	// HLSストリームライブラリヘッダ

#define AXIS_BYTE_WIDTH 32
#define FIX_T_WIDTH 1
#define FIX_T_BITS_WIDTH FIX_T_WIDTH * 8
#define LAYER1_PARAM 784

#define ITERATE_AXIS_FLIT AXIS_BYTE_WIDTH / FIX_T_WIDTH
#define ITERATE_FRAME LAYER1_PARAM / AXIS_BYTE_WIDTH

typedef ap_uint<256> uint256_t;
typedef ap_fixed<32,16> FIX_T;
uint256_t sample(hls::stream<uint256_t>& st);
