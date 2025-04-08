# Lesson 2 Exercise 2

[Original lesson](https://academy.nordicsemi.com/courses/bluetooth-low-energy-fundamentals/lessons/lesson-2-bluetooth-le-advertising/topic/blefund-lesson-2-exercise-2/)  
[Original code](https://github.com/NordicDeveloperAcademy/bt-fund/tree/main/v2.9.0-v2.7.0/l2/l2_e2_sol)  

This examples builds on the previous one, manually setting the advertising parameters and dynamically updating the advertised data.  
The original example uses a button to increment some value within the advertised information. 
To keep this example code simple, I'm incrementing the count every 5 seconds instead.

# Code changes

This example started from the L2_E1 code base and extended it.

The custom dynamic information that we want to advertise is stored in a custom ManufacturerData structure.  

Manufacturer data is a defined type in BLE, which we support by adding the manufacturerData case to the BTDataTypes enum.

A new mutating `update` method is added to the BLEAdvertisement struct, so the advertised data can be changed.  
This means the `adsd` property becomes a `var` instead of a `let`.  
Note that memory is correctly managed, when a new instance of AdvertisementAndScanResponse is created during the update, 
the previous one is de-initialized (thanks to its non Copyable nature).

# Caveats

The same caveats as in L2_E1 apply.