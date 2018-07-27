#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hls_linear_algebra.h"
#include "hls_math.h"
//typedef hls::x_complex<ap_fixed<16,8> > FIX_T;
typedef ap_fixed<32,16> FIX_T;
//typedef float FIX_T;

#define LAYER1 784
#define LAYER2 50
#define LAYER3 100
#define LAYER4 10
#define K 10

struct MULT_CONFIG_FAST: hls::matrix_multiply_traits <hls::NoTranspose,hls::NoTranspose, 1, LAYER1, LAYER1, LAYER2, FIX_T, FIX_T>{
	static const int ARCH = 2;
	static const int INNER_II = 1;
	static const int UNROLL_FACTOR = 4;
};
struct MULT_CONFIG_FAST2: hls::matrix_multiply_traits <hls::NoTranspose,hls::NoTranspose, 1, LAYER2, LAYER2, LAYER3, FIX_T, FIX_T>{
	static const int ARCH = 2;
	static const int UNROLL_FACTOR = 4;
};
struct MULT_CONFIG_FAST3: hls::matrix_multiply_traits <hls::NoTranspose,hls::NoTranspose, 1, LAYER3, LAYER3, LAYER4, FIX_T, FIX_T>{
	static const int ARCH = 2;
	static const int UNROLL_FACTOR = 4;
};

int predict(FIX_T x[1][LAYER1], FIX_T w1[LAYER1][LAYER2], FIX_T w2[LAYER2][LAYER3],
		FIX_T w3[LAYER3][LAYER4], FIX_T b1[LAYER2], FIX_T b2[LAYER3], FIX_T b3[LAYER4],
		float Gamma, float p, int mode)
{
	int i, j, k, result;
	FIX_T xx[LAYER1]; 
   	FIX_T a1[1][LAYER2], a2[1][LAYER3], a3[1][LAYER4], max, sum;
	max = -9999.9;

	int I;
	float Wsum, Psum, tmp, fb;
	float P[K], X[K], X0[K], W[K];

//#pragma HLS array_partition variable=w1 cyclic factor=8 dim=1
//#pragma HLS array_partition variable=x cyclic factor=8 dim=2
//#pragma HLS array_partition variable=w1 complete dim=1
//#pragma HLS array_partition variable=x complete dim=2
//#pragma HLS array_partition variable=w2 cyclic factor=5 dim=2
//#pragma HLS array_partition variable=a2 cyclic factor=5 dim=2
//#pragma HLS array_partition variable=w3 cyclic factor=5 dim=1
//#pragma HLS array_partition variable=b2 cyclic factor=5

	/* Exp3 */
	/* Initialization */
	if (mode == 0) {
		LOOP1: for (i = 0; i < K; i++)
			W[i] = 1;
	}
	/* Step 1 */
	Wsum = 0;
	LOOP2: for (i = 0; i < K; i++)
		Wsum += W[i];
	LOOP3: for (i = 0; i < K; i++)
		P[i] = (1 - Gamma) * W[i] / Wsum + Gamma / K;
	/* Step 2 */
	Psum = 0;
	LOOP4: for (i = 0; i < K; i++)
		Psum += P[i];
	tmp = 0;
	LOOP5: for (i = 0; i < K; i++) {
		tmp += P[i] / Psum;
		if (p <= tmp)
			break;
	}
	I = i;
	/* Step 3 */
	fb = 1;
	/* Step 4 */
	LOOP6: for (i = 0; i < K; i++) {
		if (i == I)
			X0[i] = fb / P[i];
		else
			X0[i] = 0;
		W[i] = W[i] * exp(Gamma * X0[i] / K);
	}

	// a1 = x * w1: (1, LAYER2) = (1, LAYER1) * (LAYER1, LAYER2)
	LOOP7_1: for(i = 0; i < LAYER2; i++) {
#pragma HLS PIPELINE II=1
		sum = 0;
		LOOP7_2: for(j = 0; j < LAYER1; j++) {
//#pragma HLS PIPELINE II=1
//#pragma HLS UNROLL factor=8
#pragma HLS UNROLL
			sum += x[0][j] * w1[j][i];
		}
		a1[0][i] = sum + b1[i];
		if (a1[0][i] <= 0) a1[0][i] = 0;
	}

	//hls::matrix_multiply_top <hls::NoTranspose, hls::NoTranspose, 1, LAYER2, LAYER2, LAYER3, 1, LAYER3, MULT_CONFIG_FAST2,FIX_T, FIX_T> (a1, w2, a2);
	//a2 = a1 * w2: (1, LAYER3) = (1, LAYER2) * (LAYER2 * LAYER3)
	LOOP8: for(i = 0; i < LAYER3; i++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
		a2[0][i] = b2[i];
	}

	LOOP9_1: for(i = 0; i < LAYER2; i++) {
		LOOP9_2: for (j = 0; j < LAYER3; j++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
			a2[0][j] += a1[0][i] * w2[i][j];
		}
	}

	LOOP10: for(i = 0; i < LAYER3; i++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
		if (a2[0][i] <= 0) a2[0][i] = 0;
	}

	//hls::matrix_multiply_top <hls::NoTranspose, hls::NoTranspose, 1, LAYER3, LAYER3, LAYER4, 1, LAYER4, MULT_CONFIG_FAST3, FIX_T, FIX_T> (a2, w3, a3);
	// a3 = a2 * w3: (1, LAYER4) = (1, LAYER3) * (LAYER3, LAYER4)
	LOOP11_1: for(i = 0; i < LAYER4; i++) {
		sum = 0;
		LOOP11_2: for(j = 0; j < LAYER3; j++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
			sum += a2[0][j] * w3[j][i];
		}
		a3[0][i] = sum + b3[i];
		if (a3[0][i] <= 0) a3[0][i] = 0;
	}

	max = a3[0][0];
	result = 0;
	LOOP12: for(i = 1;i < LAYER4; i++) {
#pragma HLS PIPELINE
		if(a3[0][i] > max) max = a3[0][i], result = i;
	}

    return result;
}
