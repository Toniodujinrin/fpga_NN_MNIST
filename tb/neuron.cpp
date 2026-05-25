#include "Vneuron.h"
#include "verilated.h"
#include <cstdio>
#include <cstdint>

#define N_WEIGHTS 784
#define TIMEOUT   2000  // max cycles to wait for output

static vluint64_t sim_time = 0;

void tick(Vneuron* dut) {
    dut->clk = 0; dut->eval();
    dut->clk = 1; dut->eval();
    sim_time++;
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Vneuron* dut = new Vneuron;

    // --- reset ---
    dut->reset   = 1;
    dut->x_valid = 0;
    dut->x_value = 0;
    tick(dut); tick(dut);
    dut->reset = 0;
    tick(dut);

    // --- feed inputs ---
    int sent = 0;
    while (sent < N_WEIGHTS) {

        // wait for neuron_ready
        int wait = 0;
        while (!dut->neuron_ready) {
            tick(dut);
            if (++wait > TIMEOUT) { printf("TIMEOUT waiting for ready\n"); goto done; }
        }

        // present one input value
        dut->x_valid = 1;
        dut->x_value = (uint16_t)(sent + 1);   // simple ramp, swap for real data
        tick(dut);

        dut->x_valid = 0;
        sent++;
    }

    printf("\n--- all %d inputs sent, waiting for output ---\n", N_WEIGHTS);
    for (int t = 0; t < TIMEOUT; t++) {
        tick(dut);
        if (dut->output_valid_flag) {
            printf("\n[%lu] neuron_output = %d (0x%04X)\n",
                sim_time,
                (int16_t)dut->neuron_output,   // cast to signed for display
                (uint16_t)dut->neuron_output);
            tick(dut);  // let the $display inside the module fire too
            goto done;
        }
    }
    printf("TIMEOUT waiting for output_valid_flag\n");

done:
    delete dut;
    return 0;
}
