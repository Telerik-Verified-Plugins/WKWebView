function WKWebViewPolyfill() {
}

WKWebViewPolyfill.prototype.loadFile = function (file, successCallback, errorCallback) {
  cordova.exec(successCallback, errorCallback, "WKWebViewPolyfill", "loadFile", [file]);
};

WKWebViewPolyfill.install = function () {
  if (!window.plugins) {
    window.plugins = {};
  }

  window.plugins.wkwebview = new WKWebViewPolyfill();
  return window.plugins.wkwebview;
};

cordova.addConstructor(WKWebViewPolyfill.install);