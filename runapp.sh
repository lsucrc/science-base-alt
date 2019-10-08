#!/bin/bash
cd /workdir/input
#mpirun -np $NP -machinefile /workdir/nodes.txt /model/FUNWAVE-TVD-Version_3.4/src/funwave
mpirun -np $NP -machinefile /workdir/nodes.txt /model/swan${SWAN_VER}/swan.exe
