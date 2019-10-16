# unsplash-swift

![](https://img.shields.io/badge/language-Swift--5.1-orange)
[![Swift Package Manager](https://img.shields.io/badge/spm-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![GitHub license](https://img.shields.io/github/license/jlainog/Codable-Utils)](https://github.com/jlainog/Codable-Utils/blob/master/LICENSE)

## Motivation
This Package borns as a way to create a SPM over an API and the lucky one is Unsplash 📷  

## Requirement

- iOS 12+
- XCode 11+

## Installation

### [SPM](https://github.com/apple/swift-package-manager)
```ruby
.package(url: "https://github.com/JohnSundell/Codextended", from: "0.0.1")
```

### 📷  Unsplash API 

To access the Unsplash API you need to register and create an Application [here](https://unsplash.com/oauth/applications)
Once you have an accessKey and secretKey configure the api using the line below.

```swift
Unsplash.configure(accessKey: String, secret: String)
```

### 🛠 DataTaskFactory

Each Method returns an `URLSessionDataTask`

```swift
DataTaskFactory.randomPhoto { (result) in
    switch result {
    case .success(let photo):
        dump(photo)
    default: break
    }
}.resume()
```
Currently the factory supports:

- [x] randomPhoto
- [x] searchPhotos
- [x] collection

## 📄 License

unsplash-swift is under MIT license.
