#include <stdio.h>
#include "top.h"

//typedef ap_uint<256> uint256_t;


int main(void)
{
	int i;
	uint256_t res, in;
	hls::stream<uint256_t> st;
    float val;
	uint8_t data;
	int p = 0;

	//uint256_t td[DATASIZE] = {10,20,30,40,50,60,70,80,90,100};
	fp = fopen("../../../../../src/one_images.txt", "r");
	for (i = 0; i < LAYER1; i++) {
		fscanf(fp, "%u", &data);
		in = (in<<8) | (data & 0xff);
		if (j == 31) {
			td[p] = in;
			j = 0;
			p++;
		} else {
			j++;
		}
	}
	fclose(fp);

	for (i = 0; i < ITERATE_FRAME; i++) {
		st.write(td[i]);
	}

	res = sample(st);
	int ress = (int)res;

	printf("Result: %d \n", ress);

	return 0;
}
