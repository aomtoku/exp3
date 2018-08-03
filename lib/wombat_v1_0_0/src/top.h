#include "ap_int.h"
#include "hls_stream.h"	// HLSストリームライブラリヘッダ

typedef ap_uint<256> uint256_t;
typedef ap_fixed<32,16> FIX_T;
uint256_t sample(hls::stream<uint256_t>& st);
