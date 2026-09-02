#ifndef NN_ACCELERATOR_H
#define NN_ACCELERATOR_H

#include <stddef.h>
#include <stdint.h>

#define NN_INPUT_COUNT 784u
#define NN_WEIGHT_COUNT 54912u
#define NN_BIAS_COUNT 138u

int nn_load_model(const int16_t *weights, size_t weight_count,
                  const int32_t *biases, size_t bias_count);
int nn_run(const int16_t inputs[NN_INPUT_COUNT], uint16_t *classification,
           uint32_t poll_limit);

#endif
