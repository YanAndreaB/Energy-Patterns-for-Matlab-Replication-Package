# Energy-Patterns-for-Matlab-Replication-Package

Replication package for paper "Energy Patterns for Matlab" by:
Jan-Andrea Bard; Alexander Boll; Sandro Hernández Coicochea;
Pooja Rani; Timo Kehrer

### General

- Edit `StartScript.m` so that you assign your path where you
store your GitHub-projects to the variable `reposFolder`.
All paths needed are derived from this path.
- Run `StartScript.m`.
    - This sets some variables,
    - adds locations used later to the Matlab path,
    - creates folders needed later.
- Scripts can be run section wise by pressing "Run Section"
in the Matlab editor.

### Study I

- Type `addpath Study1` into the command window.
- Run the script `EnergyTestStudy1.m`
This is to replicate the results shown in the paper in section
III.A: Study I: *Elementary Performance-oriented Coding Recommendations.*

### Study II

- Type `addpath Study2` into the command window.
- Run the script `cloneScript.m`.
This will clone the used repositories from GitHub.
- Run the script `EnergyTestStudy2.m`
This is to replicate the results shown in the paper in section
III.B: Study II: *Repository Prevalence Analysis*.

### Study III

- Type `addpath Study3` into the command window.
- Run the script `EnergyTestStudy3.m`
This is to replicate the results shown in the paper in section
III.C: Study III: *Real-World Impact Evaluation*.

### Dependencies

- Experiments must be run on a Linux computer.
Energy measurements will not work on other operating
systems.
- Experiments must be run on a computer with an Intel CPU.
Energy measurements will not work on other CPUs.
- Matlab needs to be startet with root access rights.
Energy measurements will not work without root access.