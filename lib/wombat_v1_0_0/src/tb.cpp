#include <stdio.h>
#include "top.h"
#define DATASIZE 10

//typedef ap_uint<256> uint256_t;


int main(void)
{
	int i;
	uint256_t res;
	hls::stream<uint256_t> st;

	uint256_t td[DATASIZE] = {10,20,30,40,50,60,70,80,90,100};

	for (i=0;i<DATASIZE;i++) {
		st.write(td[i]);
	}

	res = sample(st);
	int ress = (int)res;

	printf("Result: %d \n", ress);

	return 0;
}
