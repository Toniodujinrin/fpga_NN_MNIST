
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdint>
#include <cstdio>
#include "Vchunk_serializer.h"

void clock_tick(Vchunk_serializer* tb, VerilatedVcdC* trace, vluint64_t& sim_time);

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    Vchunk_serializer* tb = new Vchunk_serializer;
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

    uint32_t test_val = 0-1;   
    tb->in = test_val; 
    tb->serializer_start = 1;  
    for(size_t i{}; i < 20; i++){
      clock_tick(tb,trace,sim_time);
      printf("val: %b", tb->out); 
    } 
    trace->close();
    delete tb;
    delete trace; 
}



void clock_tick(Vchunk_serializer* tb, VerilatedVcdC* trace, vluint64_t& sim_time) {
    tb->clk = 0; tb->eval(); trace->dump(sim_time++);
    tb->clk = 1; tb->eval(); trace->dump(sim_time++);
}
