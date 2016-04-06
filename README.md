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

##How to setup

1. Initialize `PeekPanCoordinator` with a view controller's view to add a gesture recognizer and set the bounds of the panning area.

2. Set the coordinator's data source and have a return value for `maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int`. Also set the coordinator's delegate and its methods to receive updates.

3. Call `setup()` or `setup(at: index)` in `previewingContext(previewingContext:viewControllerForLocation:)` to setup the coordinator at a particular index and retreive data from the data source.

4. Call `end(true)` in `previewingContext(previewingContext:commitViewController:)` to change the state of the coordinator and reset its values.

---

1. To use `PeekPanViewController`, setup the coordinator using the directions above and set its delegate to the view controller. Also set the coordinator's data source to a class that follows its protocol. 

2. Return a view to `view(for peekPanViewController:atIndex:) -> UIView` when there's a change in index or `view(for peekPanViewController:atPercentage:) -> UIView` when the user's touch location changes. 
`PeekPanViewControllerDelegate` is a subclass of `PeekPanCoordinatorDelegate` so all of the coordinator's delegate methods are available to the view controller's delegate.

####Additional References
`PeekPan` uses some images from Behance made by the following authors licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/):

* Toros Köse - [toroskose](https://www.behance.net/toroskose) : “[Iceland 2015](https://www.behance.net/gallery/30086475/Iceland-2015)”
* Hakob Minasian - [HakobDesigns](https://www.behance.net/HakobDesigns) : “[Concept Art Portfolio](https://www.behance.net/gallery/33121401/Concept-Art-Portfolio)”
* Vivien Bertin - [vivienbertin](https://www.behance.net/vivienbertin) : “[Line-up #3](https://www.behance.net/gallery/22853885/Line-up-3)”
* Alberto Seveso - [indiffident](https://www.behance.net/indiffident) : “[Quinteassential](https://www.behance.net/gallery/25970129/Quinteassential)”
