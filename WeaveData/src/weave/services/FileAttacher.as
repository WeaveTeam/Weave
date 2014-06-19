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

package weave.services
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableObject;
	import weave.api.registerDisposableChild;
	import weave.api.reportError;
	
	/**
	 * Attaches files to the current session to be embedded in exported .weave archives.
	 */
	public class FileAttacher implements IDisposableObject
	{
		private var
			fr:FileReference,
			relevantContext:Object,
			fileFilters:Array,
			urlHandler:Function,
			errorHandler:Function;
		
		/**
		 * @param relevantContext
		 * @param fileFilters Each item should be either a FileFilter or an Array of params for the FileFilter constructor.
		 * @param urlHandler function(url:String)
		 * @param errorHandler function(event:IOErrorEvent)
		 */
		public function FileAttacher(relevantContext:Object, fileFilters:Array, urlHandler:Function, errorHandler:Function = null)
		{
			if (fileFilters)
				fileFilters = fileFilters.map(function(filter:Object, i:*, a:*):FileFilter {
					if (filter is Array)
						filter = new FileFilter(filter[0], filter[1], filter[2]);
					return FileFilter(filter);
				});
			
			registerDisposableChild(relevantContext, this);
			this.relevantContext = relevantContext;
			this.fileFilters = fileFilters;
			this.urlHandler = urlHandler;
			this.errorHandler = errorHandler;
		}

		/**
		 * @return true if FileReference.browse() was called successfully.
		 */
		public function browseAndAttachFile():Boolean
		{
			if (fr)
			{
				reportError("Please wait until the previous file attachment finishes.");
				return false;
			}
			
			try
			{
				fr = new FileReference();
				fr.addEventListener(Event.SELECT, selected);
				fr.addEventListener(ProgressEvent.PROGRESS, progress);
				fr.addEventListener(Event.COMPLETE, complete);
				fr.addEventListener(IOErrorEvent.IO_ERROR, error);
				fr.browse(fileFilters);
				return true;
			}
			catch (e:Error)
			{
				reportError(e);
			}
			return false;
		}
		
		private function selected(event:Event):void
		{
			if (!fr)
				return;
			fr.load();
			WeaveAPI.ProgressIndicator.addTask(fr, relevantContext as ILinkableObject);
		}
		private function progress(event:ProgressEvent):void
		{
			if (!fr)
				return;
			WeaveAPI.ProgressIndicator.updateTask(fr, event.bytesLoaded / event.bytesTotal);
		}
		private function complete(event:Event):void
		{
			if (!fr)
				return;
			var url:String = WeaveAPI.URLRequestUtils.saveLocalFile(fr.name, fr.data);
			cancel();
			if (urlHandler != null)
				urlHandler(url);
		}
		private function error(event:IOErrorEvent):void
		{
			if (!fr)
				return;
			cancel();
			if (errorHandler != null)
				errorHandler(event);
			else
				reportError(event);
		}
		
		/**
		 * Cancel active file attachment.
		 */
		public function cancel():void
		{
			WeaveAPI.ProgressIndicator.removeTask(fr);
			fr = null;
		}
		
		public function dispose():void
		{
			cancel();
		}
	}
}
