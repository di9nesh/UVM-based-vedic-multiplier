import uvm_pkg::*;
`include "uvm_macros.svh"
import ved_pkg::*;

class ved_test_random_cov extends ved_base_test;
  `uvm_component_utils(ved_test_random_cov)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    ved_rand_seq seq;

    phase.raise_objection(this);

    seq = ved_rand_seq::type_id::create("seq");
    seq.n_items = 5000; // increase for >95% functional coverage typically
    seq.start(env.agt.sqr);

    repeat (10) @(posedge env.agt.vif.clk);

    phase.drop_objection(this);
  endtask
endclass
