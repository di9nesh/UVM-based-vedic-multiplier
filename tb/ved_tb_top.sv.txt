`timescale 1ns/1ps
import uvm_pkg::*;
`include "uvm_macros.svh"
import ved_pkg::*;

module ved_tb_top;

  bit clk;
  always #5 clk = ~clk;  // 100MHz

  // Interface
  ved_if vif(clk);

  // DUT
  ved_64x64 dut (
    .clk    (clk),
    .a      (vif.a),
    .b      (vif.b),
    .result (vif.result)
  );

  // Assertions
  ved_assertions sva(.vif(vif));

  initial begin
    clk = 0;
    // Provide vif to UVM
    uvm_config_db#(virtual ved_if)::set(null, "*", "vif", vif);

    // Run test (set via +UVM_TESTNAME=...)
    run_test();
  end

endmodule
