# DocumentValidatorKit

On-device document type verification SDK for iOS.

Detect whether an uploaded image is:

* Driver License
* Business Document
* Not a Document

Runs entirely offline using CoreML + Vision.
No API calls. No data leaves the device.

---

## Features

* ML-powered document classification
* Screenshot rejection
* Selfie / random photo detection
* Real-world physics validation (anti-spoof)
* Async/await API
* Swift Package Manager compatible

---

## Installation

### Swift Package Manager

Add dependency:

https://github.com/ethanvanorton/DocumentValidatorKit

---

## Usage

```swift
import DocumentValidatorKit

let result = try await DocumentValidator.validate(image, expected: .driversLicense)

if result.isValid {
    print("Accepted")
} else {
    print(result.reason)
}
```

---

## Example Output

```
detected: driversLicense
confidence: 99.7%
```

---

## How it Works

1. CoreML classifies document type
2. Vision validates real-world properties
3. Safety gate rejects digital spoofs

Hybrid AI + heuristic verification pipeline.

---

## Demo App

See example usage:
https://github.com/ethanvanorton/DocumentLab

---

## License

MIT
