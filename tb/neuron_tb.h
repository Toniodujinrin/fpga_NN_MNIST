#include <cstdio>
#include <verilated.h>
#include "testbench.h"
#include <cstdint>
#define DUT Testbench<MODULE>::mcore
template <typename MODULE>
class Neuron_tb : public Testbench<MODULE> {
public:

  int cycle = 0;

  void apply_signals(){

    // --- Stimulus phase ---
    if (cycle < 16) {
      DUT->x_value = cycle;
      DUT->x_valid = 1;
    } 
    else {
      // --- Drain pipeline ---
      DUT->x_valid = 0;
      DUT->x_value = 0;
    }

    Testbench<MODULE>::tick();

    // --- Observe AFTER clock ---
    printf("cycle=%2d | x_valid=%d x=%2d | out_valid=%d out=%d\n",
        cycle,
        DUT->x_valid,
        DUT->x_value,
        DUT->output_valid,
        DUT->neuron_output
    );

    cycle++;
    // stop after enough cycles to flush pipeline
    if (cycle > 40) {
      exit(0);
    }
  }
};
