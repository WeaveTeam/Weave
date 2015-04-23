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

package weave.core
{
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.rpc.AsyncToken;
	
	import weave.api.core.ILinkableVariable;
	import weave.api.registerLinkableChild;
	
	/**
	 * This is a LinkableString that handles the process of managing a promise for file content from a URL.
	 * @author pkovac
	 * @see weave.core.LinkableVariable
	 */
	public class LinkableFile implements ILinkableVariable
	{
		private var contentPromise:LinkablePromise;
		private var url:LinkableString;

		public function LinkableFile(defaultValue:String = null, taskDescription:* = null)
		{
			contentPromise = registerLinkableChild(this, new LinkablePromise(requestContent, null, taskDescription));
			url = registerLinkableChild(contentPromise, new LinkableString(defaultValue));
		}

		private function requestContent():AsyncToken
		{
			if (!url.value)
				return null;
			return WeaveAPI.URLRequestUtils.getURL(contentPromise, new URLRequest(url.value), 'binary', true);
		}

		public function get result():ByteArray
		{
			return contentPromise.result as ByteArray;
		}

		public function get error():Object
		{
			return contentPromise.error;
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
