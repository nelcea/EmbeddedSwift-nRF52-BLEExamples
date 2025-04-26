# Lesson 2 Exercise 1

[Original lesson](https://academy.nordicsemi.com/courses/bluetooth-low-energy-fundamentals/lessons/lesson-2-bluetooth-le-advertising/topic/blefund-lesson-2-exercise-1/)  
[Original code](https://github.com/NordicDeveloperAcademy/bt-fund/tree/v2.9.0-v2.7.0/l2/l2_e1_sol)  

This example sets up the BLE stack and perform a non-connectable advertising, having the device behave as a beacon.

# Project overview

Configure the project to use Bluetooth, updating prj.conf with
```
CONFIG_BT=y
CONFIG_BT_DEVICE_NAME="SwiftBeacon"
```
This also defines the advertised device name in a constant that can be picked up from the code.

We'll also need access to the Bluetooth API from the code, so update BridgingHeader.h, adding
```C
#include <zephyr/bluetooth/bluetooth.h>
```

The first step is to enable the BLE stack, this is one single C call that I encapsulated into the BLE struct for convenience.  
The constructor prints a fatal error message in case of problem, it could be updated to throw specific Errors based on the returned error code.

The next step is to create the advertisement packet that the BLE stack will broadcast.  
The information contained in these packets is defined as different types in BLE.  
This is represented by the BTDataTypes enum, using an associated value for the actual information.  
This can then be converted to BTData, a struct holding the byte representations of a BTDataTypes.  
The complete information a device can provide is contained by the combination of the advertisement and scan response packets.  
Both contain a list of data structures (BTData in this case).  
I use an AdvertisementAndScanResponse non copyable struct to encapsulate all this information, making it easier to manage the allocated memory.  

Finally the BLEAdvertisement struct is used for the advertisement process.  
It holds the flags and the data and in this example, offers a single method to start advertising.

# Caveats

The original C code uses Zephyr macros to define the advertising data statically.  
Those macros are quite complex and Swift C Interop can not really handled them.  
In this code, the data is built dynamically using custom Swift types and memory allocation on the heap.  
I might explore another route (Swift macros ?) to define the data statically in the future.


The BTURI type uses a lookup table to handle scheme encoding.  
This is implemented using a Dictionary with keys being String.  
For this to work, linking with libswiftUnicodeDataTables.a is required.  
This can be seen in CMakeLists.txt  
This generates a lot of warning at the end of the build process.
You can ignore them but I want to further explore the topic, see how those can be fixed and write about it in an upcoming article.
