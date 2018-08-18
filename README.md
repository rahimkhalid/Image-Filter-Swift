# Image-Filter-Swift

This is an implementation of CoreImage with CIFilters, using Apple's default filters and custom filters.

The app fetches frames from your camera at ~30 FPS and allows you to capture pictures along with applying filters and preview the output of those filters, even allows user to set delay for image capture. 

## Requirements

- Xcode 8
- iOS 10
- Swift 4.1

## Usage

To use this app, open **ImageFilterSwift.xcodeproj** in Xcode 8 and run it on a device with iOS 10. (Don't use simulator as it don't have access to camera).

## Results

These are the results of the app when tested on iPhone 7. 

![image filter](demo.gif)
