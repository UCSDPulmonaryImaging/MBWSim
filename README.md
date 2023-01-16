# MBWSim
MatLab Simulation of a simple 2-compartment lung for exploring Second effects

These are the MatLab files for the MBW simulation used in the Paper in JAPPL.
Author: G. Kim Prisk
kprisk@health.ucsd.edu

Submitted Jan 15, 2023

This is a deliberately simple simulation of a MBW from a 2 compartment lung.  The two compartments together inspire 1 liter
The TV to each is apportioned.
The FRC of each can be set
This serves to define the specific ventilation for each.
There is a simplistic sequencing parameter that determines to what degree the higher SV compartment empties early.
In order to generate a Phase III slope there needs to be SV difference -AND- sequencing.  Both are required.

Sacin is not explicitly simulated, but you can add in a fized offset of SnIII that mimics this

There is not commen deadsapce, instead we use masss balance to "pretend" there is one.
CO2 is fixed at 5%
