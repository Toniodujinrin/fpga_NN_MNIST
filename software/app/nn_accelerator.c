#include "nn_accelerator.h"

#include "io.h"
#include "system.h"

#define NN_REG_CONTROL      0x00
#define NN_REG_STATUS       0x04
#define NN_REG_MODEL_TARGET 0x08
#define NN_REG_MODEL_DATA   0x0c
#define NN_REG_MODEL_COUNT  0x10
#define NN_REG_MODEL_SIZE   0x14
#define NN_REG_INPUT_DATA   0x20
#define NN_REG_OUTPUT_DATA  0x24

#define NN_CONTROL_START        (1u << 0)
#define NN_CONTROL_LOAD_BEGIN   (1u << 1)
#define NN_CONTROL_LOAD_COMMIT  (1u << 2)

#define NN_STATUS_IDLE          (1u << 1)
#define NN_STATUS_INPUT_READY   (1u << 2)
#define NN_STATUS_BUSY          (1u << 3)
#define NN_STATUS_LOAD_MODE     (1u << 4)
#define NN_STATUS_MODEL_VALID   (1u << 5)
#define NN_STATUS_RESULT_VALID  (1u << 6)
#define NN_STATUS_ERROR         (1u << 7)

static uint32_t nn_read(uint32_t offset)
{
    return IORD_32DIRECT(FPGA_NN_MNIST_RTL_0_BASE, offset);
}

static void nn_write(uint32_t offset, uint32_t value)
{
    IOWR_32DIRECT(FPGA_NN_MNIST_RTL_0_BASE, offset, value);
}

int nn_load_model(const int16_t *weights, size_t weight_count,
                  const int32_t *biases, size_t bias_count)
{
    size_t i;

    if (weights == NULL || biases == NULL ||
        weight_count != NN_WEIGHT_COUNT || bias_count != NN_BIAS_COUNT)
        return -1;

    if ((nn_read(NN_REG_STATUS) & NN_STATUS_IDLE) == 0)
        return -2;

    nn_write(NN_REG_CONTROL, NN_CONTROL_LOAD_BEGIN);
    if ((nn_read(NN_REG_STATUS) & (NN_STATUS_LOAD_MODE | NN_STATUS_ERROR)) !=
            NN_STATUS_LOAD_MODE ||
        nn_read(NN_REG_MODEL_COUNT) != 0 ||
        nn_read(NN_REG_MODEL_TARGET) != 0x00010000u)
        return -3;

    for (i = 0; i < weight_count; ++i)
        nn_write(NN_REG_MODEL_DATA, (uint16_t)weights[i]);

    for (i = 0; i < bias_count; ++i)
        nn_write(NN_REG_MODEL_DATA, (uint32_t)biases[i]);

    if (nn_read(NN_REG_MODEL_COUNT) != nn_read(NN_REG_MODEL_SIZE))
        return -4;

    nn_write(NN_REG_CONTROL, NN_CONTROL_LOAD_COMMIT);
    if ((nn_read(NN_REG_STATUS) & (NN_STATUS_MODEL_VALID | NN_STATUS_ERROR)) !=
        NN_STATUS_MODEL_VALID)
        return -5;

    return 0;
}

int nn_run(const int16_t inputs[NN_INPUT_COUNT], uint16_t *classification,
           uint32_t poll_limit)
{
    uint32_t i;
    uint32_t status;

    if (inputs == NULL || classification == NULL)
        return -1;

    nn_write(NN_REG_CONTROL, NN_CONTROL_START);
    do {
        status = nn_read(NN_REG_STATUS);
    } while ((status & NN_STATUS_BUSY) == 0 && poll_limit-- != 0);
    if ((status & NN_STATUS_BUSY) == 0)
        return -2;

    for (i = 0; i < NN_INPUT_COUNT; ++i)
        nn_write(NN_REG_INPUT_DATA, (uint16_t)inputs[i]);

    do {
        status = nn_read(NN_REG_STATUS);
    } while ((status & NN_STATUS_RESULT_VALID) == 0 && poll_limit-- != 0);
    if ((status & NN_STATUS_RESULT_VALID) == 0)
        return -3;

    *classification = (uint16_t)nn_read(NN_REG_OUTPUT_DATA);
    return 0;
}
