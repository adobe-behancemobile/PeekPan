# PeekPan

`PeekPan` combines 3D Touch and pan gestures to cycle through a collection of views while Peeking.

It's possible to have a gesture recognizer track the user's touch location while Peeking.  
This just provides a way to travel through a range of indices with the mechanics figured out.

<p align="center">
<img src="https://cloud.githubusercontent.com/assets/16088907/14086396/eec39b38-f4f2-11e5-9fa8-dfe111c1dc1c.gif"/>
</p>

The main files used in this library are:  

* `PeekPanGestureRecognizer.swift`:  
Begins tracking the user's touch location once the Peek preview is displayed and ends once the touch is released.

* `PeekPanCoordinator.swift`:  
Correlates the user's touch location to a range of indices within an adjustable panning area.

* `PeekPanViewController.swift`:  
A `UIViewController` used as an optional way to display different `UIView` on the Peek preview.

##Getting started via CocoaPods

```
sudo gem install cocoapods
```

Create a `Podfile` in your project directory:
```
pod init
```

Add the following to your `Podfile` project's target:
```
pod 'PeekPan'
```

Then run CocoaPods with `pod install`.

Finally, include `PeekPanCoordinator.swift`, `PeekPanGestureRecognizer.swift`, and *(optional)* `PeekPanViewController.swift` in your project.
Make sure to include a bridging header that imports `<UIKit/UIGestureRecognizerSubclass.h>` for `PeekPanGestureRecognizer.swift` to build correctly.

The component is targeted for use with iOS 9 but can support iOS 8 and greater.

####Additional References
`PeekPan` uses some images from Behance made by the following authors licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/):

* Toros Köse - [toroskose](https://www.behance.net/toroskose) : “[Iceland 2015](https://www.behance.net/gallery/30086475/Iceland-2015)”
* Hakob Minasian - [HakobDesigns](https://www.behance.net/HakobDesigns) : “[Concept Art Portfolio](https://www.behance.net/gallery/33121401/Concept-Art-Portfolio)”
* Vivien Bertin - [vivienbertin](https://www.behance.net/vivienbertin) : “[Line-up #3](https://www.behance.net/gallery/22853885/Line-up-3)”
* Alberto Seveso - [indiffident](https://www.behance.net/indiffident) : “[Quinteassential](https://www.behance.net/gallery/25970129/Quinteassential)”
