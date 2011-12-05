/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/


package weave.data.AttributeColumns
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.data.IQualifiedKey;
	import weave.api.reportError;

	public class ImageColumn extends DynamicColumn
	{
		public function ImageColumn()
		{
		}
		
		[Embed( source="/weave/resources/images/missing.png")]
		private static var _missingImageClass:Class;
		private static const _missingImage:BitmapData = Bitmap(new _missingImageClass()).bitmapData;
		
		/**
		 * This is the image cache.
		 */
		private static const _urlToImageMap:Object = new Object(); // maps a url to a BitmapData
		
		/**
		 * This function returns BitmapData objects as its default dataType.
		 * @inheritDoc
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (dataType != null && dataType != BitmapData)
				return super.getValueFromKey(key, dataType);
			
			var url:String = super.getValueFromKey(key, String) as String;
			if (url && _urlToImageMap[url] === undefined) // only request image if not already requested
			{
				_urlToImageMap[url] = null; // set this here so we don't make multiple requests
				WeaveAPI.URLRequestUtils.getContent(new URLRequest(url), handleImageDownload, handleFault, url);
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