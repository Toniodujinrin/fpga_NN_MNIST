
#include <cstddef>
#include <string>
#include <sys/types.h>
#include <vector>
#include <unordered_map>
#include <cstdint>
#include <cstdio>
#include <iostream>
#include <algorithm>


enum class Encoding{
  binary, 
  hex, 
  octal, 
};



void trim(std::string &s) {
    // Trim leading whitespace
    size_t first = s.find_first_not_of(" \t\n\r\f\v");
    if (std::string::npos == first) {
        s.clear();
        return;
    }
    // Trim trailing whitespace
    size_t last = s.find_last_not_of(" \t\n\r\f\v");
    s = s.substr(first, (last - first + 1));
}

double int_to_fixed_point(size_t int_width, size_t total_width, int16_t val){
  uint16_t mask = 0; 
  mask = ~mask;
  size_t decimal_width = total_width-int_width-1; 
  uint16_t decimal_mask = mask >>((sizeof(val)*8)-(decimal_width));
  int integer_portion = (val >> decimal_width);  
  uint16_t decimal_portion = val&decimal_mask;
  double decimal = (double)decimal_portion/(1<<decimal_width); 
  return integer_portion + decimal; 
}


void analyze_bit_string(size_t chunk_size, const std::string& string_val, Encoding encoding_type,
  size_t int_width, std::unordered_map<size_t, double>& dict){ 
  size_t char_size; 
  size_t base; 
  switch (encoding_type) {
    case Encoding::binary:
      char_size = 1; 
      base = 2; 
    case Encoding::octal:
      char_size = 3;
      base = 8; 
    case Encoding::hex: 
      char_size = 4;
      base = 16; 
  }
   
  
  std::string current_val = ""; 

  for(size_t i{};i < std::size(string_val); i++){
   if(std::size(current_val)*char_size == chunk_size){ 
    int val = std::stoi(current_val,0,base);
    int key = int(((std::size(string_val)-i)*char_size)/chunk_size); 
    dict.insert({key,int_to_fixed_point(int_width, chunk_size, val)});
    current_val = string_val[i]; 
   }
   else{
     current_val += string_val[i]; 
   }
  }

  int val = std::stoi(current_val,0,base);
  dict.insert({0,int_to_fixed_point(int_width, chunk_size, val)}); 
}



int main(int argc, char**argv){
  std::string encoded_string = ""; 
  if(argc >= 2){
    encoded_string = argv[1];
    trim(encoded_string); 
  }
  if(!encoded_string.empty()){
    std::unordered_map<size_t, double> dict; 
    analyze_bit_string(16,encoded_string, Encoding::hex,7,dict);  
    for(auto& val:dict){
      printf("%ld : %f\n",val.first,val.second); 
    }
  }
}
