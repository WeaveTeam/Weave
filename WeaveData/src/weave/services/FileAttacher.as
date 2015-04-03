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
				fr.addEventListener(Event.CANCEL, function(e:Event):void { cancel(); });
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
