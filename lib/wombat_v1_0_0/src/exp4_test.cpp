#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ap_fixed.h>
#include <time.h>
#include "hls_math.h"
#define LAYER_SIZE 3
#define LAYER1 784
#define LAYER2 50
#define LAYER3 100
#define LAYER4 10
#define K 10
//#define BUFSIZ 4000
//typedef float FIX_T;
typedef ap_fixed<32,16> FIX_T;

int predict(FIX_T x[1][LAYER1], FIX_T w1[LAYER1][LAYER2], FIX_T w2[LAYER2][LAYER3],
		FIX_T w3[LAYER3][LAYER4], FIX_T b1[LAYER2], FIX_T b2[LAYER3], FIX_T b3[LAYER4],
		float Gamma, float p, int mode);

int main()
{
    FIX_T x[1][LAYER1];
    FIX_T w1[LAYER1][LAYER2], w2[LAYER2][LAYER3], w3[LAYER3][LAYER4];
    FIX_T b1[LAYER2], b2[LAYER3], b3[LAYER4];
    int result;
    FILE *fp;
    int i,j;
    float val;
    int t, T, r, mode;
    float Gamma, p;

    fp = fopen("../../../../../src/one_images.txt", "r");
    for (i = 0; i < LAYER1; i++) {
    	fscanf(fp, "%f", &val);
    	x[0][i] = val / 255.0;
    }
    fclose(fp);

    fp = fopen("../../../../../src/adam-ep10-val_loss0.10329-val_acc0.97080.txt", "r");
    for (i = 0; i < LAYER1; i++) {
    	for (j = 0; j < LAYER2; j++) {
    		fscanf(fp, "%f", &val);
    		w1[i][j] = val;
    	}
    }
    for (i = 0; i < LAYER2; i++) {
      	for (j = 0; j < LAYER3; j++) {
      		fscanf(fp, "%f", &val);
        	w2[i][j] = val;
        }
     }
    for (i = 0; i < LAYER3; i++) {
      	for (j = 0; j < LAYER4; j++) {
      		fscanf(fp, "%f", &val);
        	w3[i][j] = val;
        }
     }
    for (i = 0; i < LAYER2; i++) {
    	fscanf(fp, "%f", &val);
    	b1[i] = val;
    }
    for (i = 0; i < LAYER3; i++) {
    	fscanf(fp, "%f", &val);
    	b2[i] = val;
    }
    for (i = 0; i < LAYER4; i++) {
    	fscanf(fp, "%f", &val);
    	b3[i] = val;
    }
    fclose(fp);

    srand((unsigned)time(NULL));
    T = 1;
    Gamma = 0.5;

    for (t = 0; t < T; t++) {
    	if (t == 0)
    		mode = 0;
    	else
    		mode = 1;
    	r = rand() % 10000;
    	p = (float)r / 10000.0;
    	result = predict(x, w1, w2, w3, b1, b2, b3, Gamma, p, mode);
    	printf("result = %d\n", result);
    }

	return 0;
}
