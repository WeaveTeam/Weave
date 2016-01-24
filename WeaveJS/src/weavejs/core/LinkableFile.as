/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weavejs.core
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableVariable;
	import weavejs.net.URLRequest;
	import weavejs.util.WeavePromise;
	
	/**
	 * A promise for file content, given a URL.
	 */
	public class LinkableFile implements ILinkableVariable
	{
		private var linkablePromise:LinkablePromise;
		private var url:LinkableString;
		private var responseType:String;

		public function LinkableFile(defaultValue:String = null, taskDescription:* = null, responseType:String = "uint8array")
		{
			this.responseType = responseType;
			linkablePromise = Weave.linkableChild(this, new LinkablePromise(requestContent, taskDescription));
			url = Weave.linkableChild(linkablePromise, new LinkableString(defaultValue));
		}

		private function requestContent():WeavePromise
		{
			if (!url.value)
				return null;
			var request:URLRequest = new URLRequest(url.value);
			request.responseType = responseType;
			return WeaveAPI.URLRequestUtils.request(linkablePromise, request);
		}

		public function get result():Object
		{
			return linkablePromise.result as Object;
		}

		public function get error():Object
		{
			return linkablePromise.error;
		}

		public function setSessionState(value:Object):void
		{
			url.setSessionState(value);
		}

		public function getSessionState():Object
		{
			return url.getSessionState();
		}

		public function get value():String
		{
			return url.value;
		}

		public function set value(new_value:String):void
		{
			url.value = new_value;
		}
	}
}
