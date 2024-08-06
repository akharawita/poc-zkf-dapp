pragma circom 2.1.3;

template SwapMultiplier () {  
   // Declaration of signals.  
   signal input a;  
   signal input b;  
   signal output c;  

   // Constraints.  
   c <== a * b;  
}

component main = SwapMultiplier();