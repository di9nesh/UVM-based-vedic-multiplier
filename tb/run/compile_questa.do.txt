vlib work
vlog -sv +acc \
  ../rtl/vedic_64x64.sv \
  ../tb/ved_if.sv \
  ../tb/ved_assertions.sv \
  ../tb/ved_pkg.sv \
  ../tb/tests/ved_test_basic.sv \
  ../tb/tests/ved_test_corner.sv \
  ../tb/tests/ved_test_random_cov.sv \
  ../tb/ved_tb_top.sv
