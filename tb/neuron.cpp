#include <verilated.h> 
#include "Vfpga_NN_MNIST.h"
#include <iostream>
#include <cstdint>
#include "neuron_tb.h"
#include <random>

int main(){
    //seed randmon number generator
    std::random_device rd; 
    std::mt19937 gen(rd());

    
    
    Neuron_tb<Vfpga_NN_MNIST>* tb = new Neuron_tb<Vfpga_NN_MNIST>;
    tb->reset();
    while(!tb->done()){
      tb->apply_signals(); 
    }
    exit(EXIT_SUCCESS); 
}


