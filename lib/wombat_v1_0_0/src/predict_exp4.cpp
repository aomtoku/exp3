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
#define N 5

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
	float Wsum, Esum, Psum, tmp, fb;
	float P[K], X[K], X0[K], W[N], Y0[N];
	float E[N][K] = {
		    {0.0, 0.1, 0.0, 0.3, 0.0, 0.2, 0.0, 0.2, 0.0, 0.2},
		    {0.0, 0.0, 0.0, 0.4, 0.0, 0.3, 0.0, 0.0, 0.0, 0.3},
		    {0.0, 0.0, 0.0, 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1},
		    {0.0, 0.0, 0.0, 0.5, 0.0, 0.1, 0.0, 0.1, 0.0, 0.3},
		    {0.0, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3}
		};

#pragma HLS array_partition variable=w1 complete dim=1
#pragma HLS array_partition variable=x complete dim=2
#pragma HLS array_partition variable=w2 cyclic factor=5 dim=2
#pragma HLS array_partition variable=a2 cyclic factor=5 dim=2
#pragma HLS array_partition variable=w3 cyclic factor=5 dim=1
#pragma HLS array_partition variable=b2 cyclic factor=5

	/* Exp4 */
	/* Initialization */
	if (mode == 0) {
		LOOP1: for (i = 0; i < N; i++) {
			W[i] = 1;
		}
	}
	/* Step 1 */
	Wsum = 0;
	LOOP2: for (i = 0; i < N; i++)
		Wsum += W[i];
	LOOP3_1: for (j = 0; j < K; j++) {
		tmp = 0;
		LOOP3_2: for (i = 0; i < N; i++)
			tmp += W[i] * E[i][j] / Wsum;
		P[j] = (1 - Gamma) * tmp + Gamma / K;
	}
	/* Step 2 */
	Psum = 0;
	LOOP4: for (j = 0; j < K; j++)
		Psum += P[j];
	tmp = 0;
	LOOP5: for (j = 0; j < K; j++) {
		tmp += P[j] / Psum;
		if (p <= tmp)
			break;
	}
	I = j;

	// a1 = x * w1: (1, LAYER2) = (1, LAYER1) * (LAYER1, LAYER2)
	LOOP6_1: for(i = 0; i < LAYER2; i++) {
#pragma HLS PIPELINE II=1
		sum = 0;
		LOOP6_2: for(j = 0; j < LAYER1; j++) {
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
	LOOP7: for(i = 0; i < LAYER3; i++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
		a2[0][i] = b2[i];
	}

	LOOP8_1: for(i = 0; i < LAYER2; i++) {
		LOOP8_2: for (j = 0; j < LAYER3; j++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
			a2[0][j] += a1[0][i] * w2[i][j];
		}
	}

	LOOP9: for(i = 0; i < LAYER3; i++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
		if (a2[0][i] <= 0) a2[0][i] = 0;
	}

	//hls::matrix_multiply_top <hls::NoTranspose, hls::NoTranspose, 1, LAYER3, LAYER3, LAYER4, 1, LAYER4, MULT_CONFIG_FAST3, FIX_T, FIX_T> (a2, w3, a3);
	// a3 = a2 * w3: (1, LAYER4) = (1, LAYER3) * (LAYER3, LAYER4)
	LOOP10_1: for(i = 0; i < LAYER4; i++) {
		sum = 0;
		LOOP10_2: for(j = 0; j < LAYER3; j++) {
#pragma HLS UNROLL factor=5
#pragma HLS PIPELINE II=1
			sum += a2[0][j] * w3[j][i];
		}
		a3[0][i] = sum + b3[i];
		if (a3[0][i] <= 0) a3[0][i] = 0;
	}

	max = a3[0][0];
	result = 0;
	LOOP11: for(i = 1;i < LAYER4; i++) {
#pragma HLS PIPELINE
		if(a3[0][i] > max) max = a3[0][i], result = i;
	}

	/* Step 3 */
	fb = a3[0][result];
	/* Step 4 */
	LOOP12: for (j = 0; j < K; j++) {
		if (j == I)
			X0[j] = fb / P[j];
		else
			X0[j] = 0;
	}
	LOOP13_1: for (i = 0; i < N; i++) {
		Y0[i] = 0;
		LOOP13_2: for (j = 0; j < K; j++)
			Y0[i] += E[i][j] * X0[j];
		W[i] = W[i] * exp(Gamma * Y0[i] / K);
	}

    return result;
}
