#include <stdio.h>
#include <stdlib.h>
#include "top.h"

int main(void)
{
	int i, j = 0;
	uint8_t data;
	int res, t, r, mode;
	float p;
	FILE *fp;
	uint256_t in, td[ITERATE_FRAME];
	hls::stream<uint256_t> st;

	const float gamma = 0.5;
	const int T = 5;
	srand((unsigned)time(NULL));

	fp = fopen("../../../../../src/one_images.txt", "r");
	for (i = 0; i < LAYER1_PARAM; i++) {
		fscanf(fp, "%u", &data);
		in = (in<<8) | (data & 0xff);
		if (j+1 % AXIS_BYTE_WIDTH == 0)
			td[j%AXIS_BYTE_WIDTH] = in;
		j++;
	}
	fclose(fp);

	for (i = 0; i < ITERATE_FRAME; i++) {
		st.write(td[i]);
	}

	for (t = 0; t < T; t++) {
		if (t == 0)
			mode = 0;
		else
			mode = 1;
		r = rand() % 10000;
		p = (float)r / 10000.0;
		res = sample(st, gamma, p, mode);
		printf("Result: %d \n", res);
	}

	return 0;
}
