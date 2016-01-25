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
		public var locale:String = null;
		public var reverseLayout:Boolean = false;
		
		public function loadFromUrl(jsonUrl:String):WeavePromise
		{
			var request:URLRequest = new URLRequest(jsonUrl);
			request.responseType = ResponseType.JSON;
			return WeaveAPI.URLRequestUtils.request(null, request).then(setData);
		}
		
		private function setData(value:Object):void
		{
			this.data = value;
		}
		private var _data:Object = {};
		
		public function set data(value:Object):void
		{
			_data = value;
		}
		
		public function getText(text:String):String
		{
			var result:String;
			
			if (_data.hasOwnProperty(text))
				result = _data[text];
			else // make the original text appear in the lookup table even though there is no translation yet.
				_data[text] = null;
			
			if (!result && locale == 'piglatin')
				return makePigLatins(text);
			
			return result || text;
		}
		
		//-------------------------------------------------------------
		// for testing
		private function makePigLatins(words:String):String
		{
			var r:String = '';
			for each (var word:String in words.split(' '))
				r += ' ' + makePigLatin(word);
			return r.substr(1);
		}
		private function makePigLatin(word:String):String
		{
			var firstVowelPosition:int = word.length;
			var vowels:Array = ["a", "e", "i", "o", "u", "y"];
			for each (var l:String in vowels)
			{
				if (word.indexOf(l) < firstVowelPosition && word.indexOf(l) != -1)
					firstVowelPosition = word.indexOf(l);
			}
			return  word.substring(firstVowelPosition, word.length) +
				word.substring(0, firstVowelPosition) +
				"ay";
		}
	}
}
