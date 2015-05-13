/*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
*/

if(!cordova.exec.jsToNativeModes.WK_WEBVIEW_BINDING) {

	//
	//intercept iframe bridge
	//

	var exec = require('cordova/exec');

	//force bridge to be created with invalid message
	try{
		exec(null, null, 'WKWebView', '', []);
	} catch(e) {}

	//wrap nativeFetchMessages with redirect to wkwebview bridge
	var origNativeFetchMessages = exec.nativeFetchMessages;
	exec.nativeFetchMessages = function() {
		var cmds = origNativeFetchMessages();
		cmds = JSON.parse(cmds);
		for(var i=0;i<cmds.length;i++) {
			var cmd = cmds[i];
			if(cmd[1]==='WKWebView') continue;

			window.webkit.messageHandlers.cordova.postMessage(cmd);
		}
		return '';
	};

	//get ref to bridge
	var bridge;
	var ifrs = document.getElementsByTagName('iframe');
	for(var i=0;i<ifrs.length;i++) {
		var ifr = ifrs[i];
		if(ifr.style.display==='none') {
			bridge = ifr;
			break;
		}
	}

	//add setter that calls (wrapped) nativeFetchMessages
	ifr.__defineSetter__ ('src', function(val){
		exec.nativeFetchMessages();
	});

	//make our setter be called
	ifr.src="";

	// a seemingly silly fix for a script error observed when a plugin returns its callback
	exec.nativeEvalAndFetch = function(func) {
		// This shouldn't be nested, but better to be safe.
		exec.isInContextOfEvalJs++;
		var retVal = '';
		try {
			func();
			retVal = exec.nativeFetchMessages();
		} finally {
			exec.isInContextOfEvalJs--;
			return retVal;
		}
	};
}