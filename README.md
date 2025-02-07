# IC-Design
## Topics
### hw1: Modular-Adder-Subtractor (2-input MAS)
### hw2: Check-in Pick-up System (CIPU)
### hw3: Matrix Multiplier (MM)
- With Gate-level simulation and performance scoring
- 95, Functional: 60/60, gate-level: 20/20, performance: 15/20
### hw4: Priority Queue (PQ)
- With Gate-level simulation and performance scoring
- 87, Functional: 60/60, gate-level: 20/20, performance: 7/20
### hw5: AES (128-bit) algorithm (encoding)
- With Gate-level simulation and performance scoring
- 88, Functional: 60/60, gate-level: 20/20, performance: 8/20
<!-- ## Time spent
- hw1: 2 hours
- hw2: About 4 days, 15 hours
- hw3: 2 hours+ 5 hours + 1 hour (pre-sim); 1 hour (synthesis); 5 hours (gate-level) credit to @TA for pointing out the mismatched clock.
- hw4: -->
## How to run
Put all `*.v` into same-level of the `hw*` directory
- Files
    - Functional Simulation slides: https://docs.google.com/presentation/d/1JMZ8A3VbgSxpCGdREvNZKVtRWuxA2qKM/edit#slide=id.p1
    - Gate-level Simulation slides: https://docs.google.com/presentation/d/1SDNdIp-VRvduzMZU3faKX-pAHeXTmkr6
- Run `vlog *.v` to check compilation results
- Run `vsim` and add files following `functional_sim` slides on Moodle/Google Slides to check the waves and functional-sim results
- Open Quartus and set up to run synthesis
- Use `*.vo` and `*.sdo` to run gate-level simulation.


## Gate-Level Simulation
### Library paths
```
/home/nanaeilish/intelFPGA/20.1/modelsim_ase/altera/verilog/altera
/home/nanaeilish/intelFPGA/20.1/modelsim_ase/altera/verilog/cycloneive
```