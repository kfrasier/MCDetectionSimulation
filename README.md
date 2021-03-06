# MCDetectionSimulation
Scripts for Monte Carlo simulation modeling echolocation click detection probability.

### Basics:
The starting point is: 
      `monteTL_3D_clickmethod.m`

Parameter choices are selected in: 
      `clickmethod_settings.m`

An example transmission loss profile (`DT07B_8radial_3DTL.mat`, 8 radials) is available upon request.


### More complexity: 
There are lots of additional layers of complexity that have not (yet?) been implemented here. 

* **Depth**:  
   Animals are assumed to be surface associated with a **lognormal** dive depth distribution. 
   However, other options are possible including diving to a consistent depth, or to a specific altitude above the seafloor. Multiphase dive profiles are also possible (e.g. X% of time in descent, Y% of time at depth.)

* **Group-based models**:  
   Only click-based detection probability is implemented here for simplicity. Group models are fairly trivial to add.
   
* **Beam pattern**:  
   As stated in the code, the beam pattern calculations used here are from Zimmer 2011, piston model estimates. 
   It would be nice to incorporate Jens Koblitz's recent modeling work.
  
