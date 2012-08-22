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

package weave.utils
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;

	public class ImageLoaderUtils extends EventDispatcher
	{
		private var _url:String = null;
		private var _request:URLRequest;
		private var _loader:Loader;
		
		private var _bitmap:Bitmap;
		
		public function ImageLoaderUtils(newURL:String = null)
		{
			if( newURL == null )
				return;
			
			url = newURL;
		}
		
		public function set url(newURL:String):void
		{
			_url = newURL;
			
			_request = new URLRequest(_url);
			_loader = new Loader();
			
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, toByteArray);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadError);
			_loader.load(_request);
		}
		
		public function get url():String	{	return _url;	}
		public function get loader():Loader {	return _loader;	}
		public function get bitmap():Bitmap {	return _bitmap; }
		
		private function toByteArray(e:Event):void
		{
			var loaderInfo:LoaderInfo = LoaderInfo(e.target);
			var byteArray:ByteArray = loaderInfo.bytes;
			
			_loader = new Loader();
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadComplete);
			_loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadError);
			_loader.loadBytes(byteArray);
		}
		private function loadComplete(e:Event):void
		{
			var loaderInfo:LoaderInfo = LoaderInfo(e.target);
			var bmd:BitmapData = new BitmapData(loaderInfo.width, loaderInfo.height);
			
			bmd.draw(loaderInfo.loader);
			_bitmap = new Bitmap(bmd);
			
			dispatchEvent(new ImageLoaderUtilsEvent(ImageLoaderUtilsEvent.LOAD_COMPLETE, e, _bitmap));
		}
		private function loadError(e:IOErrorEvent):void
		{
			dispatchEvent(new ImageLoaderUtilsEvent(ImageLoaderUtilsEvent.ERROR, e));
		}
	}
}

