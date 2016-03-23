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
	import weavejs.api.core.ILocale;
	import weavejs.net.ResponseType;
	import weavejs.net.URLRequest;
	import weavejs.util.WeavePromise;

	public class Locale implements ILocale
	{
		private var _reverseLayout:Boolean = false;
		public function get reverseLayout():Boolean { return _reverseLayout; }
		public function set reverseLayout(value:Boolean):void { _reverseLayout = value; }
		
		public function loadFromUrl(jsonUrl:String):WeavePromise
		{
			var request:URLRequest = new URLRequest(jsonUrl);
			request.responseType = ResponseType.JSON;
			var self:Locale = this;
			return WeaveAPI.URLRequestUtils.request(this, request).then(function(data:Object):void { self.data = data; });
		}
		
		private var _data:Object = {};
		
		public function get data():Object
		{
			return _data;
		}
		
		public function set data(value:Object):void
		{
			_data = value;
		}
		
		public function getText(text:String):String
		{
			if (!text)
				return '';
			
			var result:String;
			
			if (_data.hasOwnProperty(text))
				result = _data[text];
			else // make the original text appear in the lookup table even though there is no translation yet.
				_data[text] = null;
			
			return result || text;
		}
	}
}
