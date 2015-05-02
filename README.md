# BigBrother

[![Version](https://cocoapod-badges.herokuapp.com/v/BigBrother/badge.png)](http://cocoadocs.org/docsets/BigBrother) [![Platform](https://cocoapod-badges.herokuapp.com/p/BigBrother/badge.png)](http://cocoadocs.org/docsets/BigBrother)
[![Build Status](https://travis-ci.org/marcelofabri/BigBrother.svg)](https://travis-ci.org/marcelofabri/BigBrother)

> **[BIG BROTHER](http://en.wikipedia.org/wiki/Big_Brother_(Nineteen_Eighty-Four)) IS WATCHING YOU**. 

BigBrother is a Swift library made for iOS that automatically watches for any performed request and sets the [network activity indicator](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/MobileHIG/Controls.html#//apple_ref/doc/uid/TP40006556-CH15-SW44).

It was inspired by [this comment](https://github.com/Alamofire/Alamofire/issues/185#issuecomment-64955006) by [Mattt Thompson](https://github.com/mattt).

It also was based on [this tutorial](http://www.raywenderlich.com/76735/using-nsurlprotocol-swift) for creating an `NSURLProtocol` and on [`AFNetworkActivityIndicatorManager`](https://github.com/AFNetworking/AFNetworking/blob/master/UIKit%2BAFNetworking/AFNetworkActivityIndicatorManager.h) from [AFNetworking](https://github.com/AFNetworking/AFNetworking).

## Usage

### Adding

#### Adding to `NSURLConnection` and `NSURLSession.sharedSession()`
```swift
BigBrother.addToSharedSession()
```

#### Adding to a custom `NSURLSessionConfiguration`
```swift
var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

BigBrother.addToSessionConfiguration(configuration)

let session = NSURLSession(configuration: configuration)
```

### Removing

#### Removing from `NSURLConnection` and `NSURLSession.sharedSession()`
```swift
BigBrother.removeFromSharedSession()
```

#### Removing from a custom `NSURLSessionConfiguration`
```swift
var configuration = NSURLSessionConfiguration.defaultSessionConfiguration()

BigBrother.removeFromSessionConfiguration(configuration)

let newSession = NSURLSession(configuration: configuration)
```

> [**REMINDER**](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSURLSessionConfiguration_class/)
> 
> It is important to configure your NSURLSessionConfiguration object appropriately before using it to initialize a session object. Session objects make a copy of the configuration settings you provide and use those settings to configure the session. Once configured, the session object ignores any changes you make to the NSURLSessionConfiguration object. If you need to modify your transfer policies, you must update the session configuration object and use it to create a new NSURLSession object.

### Advanced usage

`BigBrother.URLProtocol` is an `NSURLProtocol` subclass that manages the network activity indicator and it's public if you want to add it yourself to an `NSURLSessionConfiguration` or to the default `NSURLProtocol` (used by `NSURLConnection` and `NSURLSession.sharedSession()`).

`BigBrother.Manager` is also public, so you can manage the network activity indicator directly:

```swift
BigBrother.Manager.sharedInstance.incrementActivityCount()

// do something...

BigBrother.Manager.sharedInstance.decrementActivityCount()
```

## Installation

BigBrother is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BigBrother', :git => 'https://github.com/marcelofabri/BigBrother'
```	

Then run `pod install` with CocoaPods 0.36 or newer.

## Unit Tests

Unit testing is done with `XCTest` and the tests are available under the [BigBrotherTests](/BigBrotherTests) folder.

## Collaborating 

- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request. They're more than welcome!

## Contact

Marcelo Fabri

- http://www.marcelofabri.com
- [@marcelofabri_](https://twitter.com/marcelofabri_)
- me@marcelofabri.com


## License

BigBrother is available under the MIT license. See the LICENSE file for more info.

