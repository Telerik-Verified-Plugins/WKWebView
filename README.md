# Cordova WKWebView Polyfill Plugin
by [Eddy Verbruggen](http://twitter.com/eddyverbruggen)

## 0. Index

1. [Description](#1-description)
2. [Screenshot](#2-screenshot)
3. [Installation](#3-installation)
4. [License](#4-license)

## 1. Description

Allows you to use the new WKWebView on iOS 8.
Falls back to UIWebView on iOS 7 and lower.

_BETA_ - things will likely break atm, [please post your feedback :)](https://github.com/EddyVerbruggen/cordova-plugin-wkwebview/issues)

* Requires building with XCode 6 (iOS 8 SDK)
* Will hopefully cease to exist soon (when Apple releases a fixed WKWebView so Cordova can use it without the hacks I needed to apply)

## 2. Screenshot
This image shows the [SocialSharing plugin] in action while running [a performance test](https://www.scirra.com/demos/c2/particles/) in an iframe.
It's a screenshot of the [demo app](demo/index.html).

<img src="screenshots/UIWebView-vs-WKWebView.png" width="700"/>

## 3. Installation

```
$ cordova plugin add https://github.com/EddyVerbruggen/cordova-plugin-wkwebview
$ cordova prepare
```

No need for anything else!

## 4. License

[The MIT License (MIT)](http://www.opensource.org/licenses/mit-license.html)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
