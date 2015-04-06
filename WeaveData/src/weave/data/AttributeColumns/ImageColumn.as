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

package weave.data.AttributeColumns
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;

	public class ImageColumn extends DynamicColumn
	{
		/**
		 * This function returns BitmapData objects as its default dataType.
		 * @inheritDoc
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType == BitmapData)
			{
				var url:String = super.getValueFromKey(key, String) as String;
				return getImageFromUrl(url);
			}
			
			return super.getValueFromKey(key, dataType);
		}
		
		//------------------------------
		
		[Embed( source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:BitmapData = Bitmap(new _missingImageClass()).bitmapData;
		
		/**
		 * This is the image cache.
		 */
		private static const _urlToImageMap:Object = new Object(); // maps a url to a BitmapData
		
		public function getImageFromUrl(url:String):BitmapData
		{
			if (url && _urlToImageMap[url] === undefined) // only request image if not already requested
			{
				_urlToImageMap[url] = null; // set this here so we don't make multiple requests
				WeaveAPI.URLRequestUtils.getContent(this, new URLRequest(url), handleImageDownload, handleFault, url);
			}
			
			return _urlToImageMap[url] as BitmapData;
		}
		
		private function handleImageDownload(event:ResultEvent, token:Object = null):void
		{
			var bitmap:Bitmap = event.result as Bitmap;
			_urlToImageMap[token] = bitmap.bitmapData;
			triggerCallbacks();
		}
				
		/**
		 * This function is called when there is an error downloading an image.
		 */
		private function handleFault(event:FaultEvent, token:Object=null):void
		{
			_urlToImageMap[token] = _missingImage;
			triggerCallbacks();
			reportError(event);
		}		
	}
}