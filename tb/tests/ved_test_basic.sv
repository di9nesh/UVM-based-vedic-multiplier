import uvm_pkg::*;
`include "uvm_macros.svh"
import ved_pkg::*;

class ved_test_basic extends ved_base_test;
  `uvm_component_utils(ved_test_basic)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    ved_corner_seq seq;

    phase.raise_objection(this);

    seq = ved_corner_seq::type_id::create("seq");
    seq.start(env.agt.sqr);

    // Let monitor/scoreboard consume last cycle
    repeat (5) @(posedge env.agt.vif.clk);

    phase.drop_objection(this);
  endtask
endclass

