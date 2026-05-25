
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdint>
#include <cstdio>
#include <iostream>
#include "Vmax_finder.h"

void clock_tick(Vmax_finder* tb, VerilatedVcdC* trace, vluint64_t& sim_time);

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vmax_finder* tb = new Vmax_finder;
    VerilatedVcdC* trace = new VerilatedVcdC;
    tb->trace(trace, 99);
    trace->open("waveform.vcd");

    vluint64_t sim_time = 0;


    //long reset 
    tb->clk = 0;
    tb->reset = 1;
    for (int i = 0; i < 8; ++i) clock_tick(tb, trace, sim_time);
    tb->reset = 0;
    tb->eval(); 

    //
    uint8_t byte = 216; 
    tb->data = byte;
    tb->start = 1; 
     
    while(!tb->out_valid){
      clock_tick(tb,trace,sim_time);
    } 
    printf("val: %b, valid: %b /n", tb->out, tb->out_valid); 

    trace->close();
    delete tb;
    delete trace; 
}


void clock_tick(Vmax_finder* tb, VerilatedVcdC* trace, vluint64_t& sim_time) {
    tb->clk = 0; tb->eval(); trace->dump(sim_time++);
    tb->clk = 1; tb->eval(); trace->dump(sim_time++);
}
