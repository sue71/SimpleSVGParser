# SimpleSVGParser
The simple SVG parser for iOS written in swift.

## Features

- convert SVG to CGPath
- written in swift
- use d attribute
- supporting multiple path

## Use

```swift

let layer = CAShapeLayer()
layer.path = SVGParser.buildPathFromSVG("sample")

self.view.layer.addSublayer(layer)

```

## Restriction

The SVG file should have "d" attributes.

## Sample data

http://www.flaticon.com
