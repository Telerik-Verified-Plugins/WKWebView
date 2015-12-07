# Cordova WKWebView Polyfill Plugin
by [Eddy Verbruggen](http://twitter.com/eddyverbruggen) / [Telerik](http://www.telerik.com)


_iOS9 warning:_ please test your app on iOS 9 and move to the 0.6.0 release if things are broken!


## 0. Index

1. [Description](#1-description)
2. [Screenshot](#2-screenshot)
3. [Installation](#3-installation)
4. [Changelog](#4-changelog)
5. [Credits](#5-credits)
6. [License](#6-license)

## 1. Description

_BETA_ - things may break, [please post your feedback :)](https://github.com/EddyVerbruggen/cordova-plugin-wkwebview/issues)

* Allows you to use the new WKWebView on iOS 8 (the simulator is supported as well).
* Falls back to UIWebView on iOS 7 and lower.
* Will hopefully cease to exist soon (when Apple releases a fixed WKWebView so Cordova can use it without the hacks I needed to apply).
* As a matter of fact, [Apache is working on a similar plugin (which you can't use at the moment of writing)](https://github.com/apache/cordova-plugins/tree/master/wkwebview-engine) which I came across after releasing version 0.1.1. It targets Cordova 3.7.0 and up whereas this plugin is supported on 3.0.0 an up. 

### Take note!

* For a seamless upgrade to iOS9 this plugin wipes any existing `NSAppTransportSecurity` configuration you may have done (a new feature in iOS9) to allow communication with even HTTP (non-S) backends, like previous iOS versions did. You can and should configure access rules (`config.xml`) and use the whitelist plugin as before.
* [Ionic](http://ionicframework.com/) tip: to prevent flashes of a black background, make sure you set `ion-nav-view`'s `background-color` to `transparent`.
* If you need the [device plugin](https://github.com/apache/cordova-plugin-device), use at least Cordova-iOS 3.6.3 (deviceready never fires with 3.5.0 due to a currently unknown reason).
* When making AJAX requests to a remote server make sure it supports CORS. See the [Telerik Verified Marketplace documentation](http://plugins.telerik.com/plugin/wkwebview) for more details on this and other valuable pointers. As a last resort you can add [this CORS-Proxy](https://github.com/gr2m/CORS-Proxy) between your app and the server.
* You can load files from the app's cache folders by using the entire path (/var/.../Library/...) or simply '/Library/..' (or '/Documents/..').
* This plugin features crash recovery: if the WKWebView crashes, it will auto-restart (otherwise you'd have an app with a blank page as it doesn't crash the app itself). Crash recovery requires a filled `<title>anything</title>` tag in your html files. If you want to disable this feature, set the `config.xml` property `DisableCrashRecovery` to `true`.
* In order to open links like `tel:` and `mailto:` you need to add `target="_blank"`: `<a href="tel:+31611223344" target="_blank">call!</a>`
* If you're trying to use `HideFormAccessoryBar` with the `cordova-plugin-keyboard` plugin, please [use version 1.1.3+ of this fork](https://www.npmjs.com/package/cordova-plugin-keyboard) which is compatbile with WKWebView.

## 2. Screenshot
This image shows the [SocialSharing plugin](https://github.com/EddyVerbruggen/SocialSharing-PhoneGap-Plugin) in action while running [a performance test](https://www.scirra.com/demos/c2/particles/) in an iframe on my iPhone 6 (older devices show an even larger difference).
It's a screenshot of the [demo app](demo/index.html).

<img src="https://raw.githubusercontent.com/Telerik-Verified-Plugins/WKWebView/master/screenshots/UIWebView-vs-WKWebView.png" width="700"/>

## 3. Installation

From npm
```
$ cordova plugin add cordova-plugin-wkwebview
```

Specify a custom port (default 12344), you can omit this if you want to use the default in case you use a recent Cordova CLI version
```
$ cordova plugin add cordova-plugin-wkwebview --variable WKWEBVIEW_SERVER_PORT=12344
```

No need for anything else - you can now open the project in XCode 6 if you like.

## 4. Changelog
ApiAISDKPlugin
* __0.6.8__  Compatibility with Telerik's LivePatch plugin. See #202. 
* __0.6.7__  Compatibility with `file://` protocol for usage in plugins like [cordova-hot-code-push](https://github.com/nordnet/cordova-hot-code-push), thanks #195 and #196!
* __0.6.5__  `KeyboardDisplayRequiresUserAction` works! So set to `false` if you want the keyboard to pop up when programmatically focussing an input field.
* __0.6.4__  On top of the port preference introduced in 0.6.3 you can now override the default variable when installing this plugin (see 'Installation').
* __0.6.3__  By default the embedded webserver uses port `12344`, but if you want to you can now override that port by setting f.i. `<preference name="WKWebViewPluginEmbeddedServerPort" value="20000" />` in `config.xml`.
* __0.6.2__  LocalStorage is copied from UIWebView to WKWebView again (iOS location was recently changed as it appears).
* __0.6.1__  Allow reading files from /tmp, so the camera plugin file URI's work. Thx #155.
* __0.6.0__  iOS9 (GM) compatibility. Also, compatibility with iOS8 devices when building with XCode 7 (iOS9 SDK). Dialogs (alert, prompt, confirm) were broken.
* __0.5.1__  Added support for `config.xml` property `DisableLocalStorageSyncWithUIWebView` (default `false`). Set it to `true` if you want to switch back to UIWebView and retain LS changes made while running WKWebView.
* __0.5.0__  iOS9 (beta) compatibility, keyboard scroll fix, white keyboard background if no specific color is specified (was black).
* __0.4.0__  Compatibility with Telerik LiveSync and LivePatch. Disabled the horizontal and vertical scrollbars. Added support for `config.xml` property `DisableCrashRecovery` (default `false`).
* __0.3.8__  Adding a way to access files in '/Library/' and '/Documents/' (simply use those prefixes), thanks #88!
* __0.3.7__  Custom URL Schemes did not work, see #98, also this version includes crash recovery, thanks #62!
* __0.3.6__  Bind embedded webserver to localhost so it can't be reached from the outside, thanks #64!
* __0.3.5__  Compatibility with the statusbar plugin: allow the statusbar to not overlay the webview, thanks #6 and #20!
* __0.3.4__  The GCDWebServer is now compatible with all iOS architectures, thanks #47 and #48!
* __0.3.2__  Switched embedded HTTP server from CocoaHTTP server to GCDWebServer, thanks #43!
* __0.3.1__  Compatibility with the SplashScreen plugin
* __0.3.0__  Enhanced loading files with the embedded HTTP server, thanks #36!
* __0.2.7__  Cut app startup time in half - not noticable unless you have a lot of files in your app, see #32
* __0.2.6__  `Config.xml` settings like `MediaPlaybackRequiresUserAction` (autoplay HTML 5 video) are now supported, see #25.
* __0.2.5__  Fixed a script error for Cordova 3.5.0 and lower, see #17.
* __0.2.4__  Compatibility with the `device` plugin on Cordova 3.5.0 and lower, see #17.
* __0.2.3__  Compatibility with the `close` function of the [Ionic Keyboard Plugin](https://github.com/driftyco/ionic-plugins-keyboard).
* __0.2.2__  Compatibility with plugins which use the superview of the 'classic' webview, like [ActivityIndicator](https://github.com/Initsogar/cordova-activityindicator)
* __0.2.1__  LocalStorage sync between UIWebView and WKWebView - on a real device as well
* __0.2.0__  LocalStorage sync between UIWebView and WKWebView - on a simulator only
* __0.1.3__  Compatibility with [InAppBrowser](https://github.com/apache/cordova-plugin-inappbrowser)
* __0.1.2__  Compatibility with plugins like [Toast](https://github.com/EddyVerbruggen/Toast-PhoneGap-Plugin) which add a subview to the webview (they didn't show)
* __0.1.1__  Cleanup to get rid of a few (deprecation) warnings - lots left (on purpose) because they're thrown by a 3rd party framework and can be safely ignored
* __0.1.0__  Added support for loading local files via XHR. This should now transparently work for $.ajax, AngularJS templateUrl's, etc. To this end the plugin adds an embedded HTTP server on port 12344 which is stopped when the app is put to sleep or exits.
* __0.0.1__  Initial version

## 5. Credits
This plugin was inspired by the hard work of the Apache Cordova team [(and most notably Shazron)](https://github.com/shazron/WKWebViewFIleUrlTest).

## 6. License

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
