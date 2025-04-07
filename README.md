# Embedded Swift BLE examples on nRF52840

## Introduction

[Nordic Semiconductor](https://www.nordicsemi.com/) have great resources about using their [nRF Connect SDK](https://www.nordicsemi.com/Products/Development-software/nRF-Connect-SDK) (based on [Zephyr](https://www.zephyrproject.org/)) on their [Nordic Developer Academy](https://academy.nordicsemi.com/).  
Their [nRF Connect SDK Fundamentals](https://academy.nordicsemi.com/courses/nrf-connect-sdk-fundamentals/) course is a great introduction to developing with Zephyr.  
And their [Bluetooth Low Energy Fundamentals](https://academy.nordicsemi.com/courses/bluetooth-low-energy-fundamentals/) course is a great resource to learn about BLE, certainly on their board but also for learning about the protocol in general.  
I would also recommend the [Ellisys Bluetooth Video Series](https://www.youtube.com/playlist?list=PLYj4Cw17Aw7ypuXt7mDFWAyy6P661TD48) on YouTube for learning about BLE.  

## About these examples

The [Bluetooth Low Energy Fundamentals](https://academy.nordicsemi.com/courses/bluetooth-low-energy-fundamentals/) course mentioned above contains quite a few code examples, all available on [GitHub](https://github.com/NordicDeveloperAcademy/bt-fund).  
But of course, they're written in C, using the Zephyr SDK APIs.  

This repository contains the same examples, converted to Swift.  
My goal was to not have to write any custom C code to perform the same functionality as the original examples.  
When I created custom Swift types, they usually implement the bare minimum for that specific example.  
I have not tried to create a higher level abstraction Swift API (e.g. to offer a Core Bluetooth compatible API), this might be something I could tackle at a later stage.

Each example contains its own README file, describing some details about the specific example but considers that your have also read the information about the original Nordic example.  