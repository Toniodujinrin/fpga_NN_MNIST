#include <verilated.h>

template<typename MODULE> 
class Testbench {
  public: 
   Testbench(void){
    mcore = new MODULE; 
    m_tickcount = 0l; 
   } 

   virtual ~Testbench(void){
    delete mcore; 
    mcore = nullptr; 
   }

   virtual void reset(void){
     m_tickcount = 0;
     mcore->reset = 1;
     this->tick(); 
     mcore->reset = 0; 
   }

   virtual void tick(void){
     m_tickcount++; 
     //pre rising edge low clock is to mimick combinational logic set-up time.  
     mcore->clk =0; 
     mcore->eval(); 
     mcore->clk = 1; 
     mcore->eval(); 
     mcore->clk = 0; 
     mcore->eval(); 
   } 

   virtual bool done(void){
     return (Verilated::gotFinish()); 
   }

    MODULE* mcore; 
    unsigned long m_tickcount; 
}; 
