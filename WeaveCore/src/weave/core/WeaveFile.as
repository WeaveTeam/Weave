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

package weave.core
{
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import weave.api.core.ILinkableObject;

	public class WeaveFile implements ILinkableObject
	{
		public function WeaveFile()
		{
			_ref = new FileReference();
			_ref.addEventListener(Event.COMPLETE, handleFileComplete);
			_typeFilter = [new FileFilter("Weave files", "*.weave")];
		}
		
		private var _ref:FileReference;
		private var _typeFilter:Array;
		public var data:ByteArray;
		
		public function browse():void
		{
			_ref.browse(_typeFilter);
		}
		
		public function save(defaultFileName:String = null):void
		{
			_ref.save(data, defaultFileName);
		}
		
		private function handleFileComplete(event:Event):void
		{
		}
	}
}
