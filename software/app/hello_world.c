/*
 * Copyright (C) 2021 Intel Corporation
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <stdio.h>

#include "model_data.h"
#include "nn_accelerator.h"

int main(void)
{
    int result = nn_load_model(model_weights, NN_WEIGHT_COUNT,
                               model_biases, NN_BIAS_COUNT);
    if (result != 0) {
        printf("Model load failed: %d\n", result);
        return result;
    }

    printf("Loaded %u weights and %u biases\n",
           NN_WEIGHT_COUNT, NN_BIAS_COUNT);
    return 0;
}
