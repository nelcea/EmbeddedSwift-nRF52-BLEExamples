# Lesson 2 Exercise 3

[Original lesson](https://academy.nordicsemi.com/courses/bluetooth-low-energy-fundamentals/lessons/lesson-2-bluetooth-le-advertising/topic/blefund-lesson-2-exercise-3/)  
[Original code](https://github.com/NordicDeveloperAcademy/bt-fund/tree/main/v2.9.0-v2.7.0/l2/l2_e3_sol)  

This examples switches to a connectable advertising in which it exposes a service UUID.  
It also shows how to define a specific BLE address for the peripheral.

# Code changes

This example started from the L2_E1 code base and extended it.

As there's no URI anymore in the advertised data, we can remove the BTURI struct and the uri case from BTDataTypes enum.  

We need to include a service UUID in the advertised data, so we add a uuid case and the BTUUID struct.  
This is a simple version of the UUID, only supporting the full 128-bit version.  

The advertising parameters being different, we replace the bt_le_adv_nconn method witha  bt_le_adv_conn3 one.  

We also want to be able to set a random static address for the device.  
The C calls to do this are encapsulated in the setAddress static method on the BLE struct.  

# Caveats

As in L2_E1, we're dynamically defining the advertising data.  
We don't use a dictionary for this example and don't need to link against the libswiftUnicodeDataTables.a library anymore.