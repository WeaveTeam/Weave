/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.core
{
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	import mx.core.IFlexDisplayObject;
	import mx.graphics.codec.PNGEncoder;
	
	import weave.utils.BitmapUtils;
	import weave.utils.OrderedHashMap;

	/**
	 * This is an interface for reading and writing data in the Weave file format.
	 * 
	 * @author adufilie
	 */
	public class WeaveArchive
	{
		/**
		 * @param input A Weave file to decode.
		 */
		public function WeaveArchive(input:ByteArray = null)
		{
			if (input)
				_readArchive(input);
		}
		
		/**
		 * This is a dynamic object containing all the files (ByteArray objects) in the archive.
		 * The property names used in this object must be valid filenames or serialize() will fail.
		 */
		public const files:OrderedHashMap = new OrderedHashMap();
		
		/**
		 * This is a dynamic object containing all the amf objects stored in the archive.
		 * The property names used in this object must be valid filenames or serialize() will fail.
		 */
		public const objects:OrderedHashMap = new OrderedHashMap();
		
		private static const FOLDER_AMF:String = "weave-amf"; // folder used for amf-encoded objects
		private static const FOLDER_FILES:String = "weave-files"; // folder used for raw files
		
		/**
		 * @private
		 */		
		private function _readArchive(fileData:ByteArray):void
		{
			var zip:Object = weave.utils.readZip(fileData, filterFilePathsToReadAsObject);
			for (var path:String in zip)
			{
				var fileName:String = path.substr(path.indexOf('/') + 1);
				if (filterFilePathsToReadAsObject(path))
					objects[fileName] = zip[path];
				else
					files[fileName] = zip[path];
			}
		}
		
		private function filterFilePathsToReadAsObject(filePath:String):Boolean
		{
			return filePath.indexOf(FOLDER_AMF + '/') == 0;
		}
		
		/**
		 * This function will create a ByteArray containing the objects that have been specified with setObject().
		 * @param contentType A String describing the type of content contained in the objects.
		 * @return A ByteArray in the Weave file format.
		 */
		public function serialize():ByteArray
		{
			var name:String;
			var zip:Object = {};
			for (name in files)
				zip[FOLDER_FILES + '/' + name] = files[name];
			for (name in objects)
				zip[FOLDER_AMF + '/' + name] = objects[name];
			return weave.utils.writeZip(zip);
		}
		
		public static const HISTORY_SYNC_DELAY:int = 100;
		public static const THUMBNAIL_SIZE:int = 200;
		public static const ARCHIVE_THUMBNAIL_PNG:String = "thumbnail.png";
		public static const ARCHIVE_SCREENSHOT_PNG:String = "screenshot.png";
		public static const ARCHIVE_PLUGINS_AMF:String = "plugins.amf";
		public static const ARCHIVE_HISTORY_AMF:String = "history.amf";
		private static const _pngEncoder:PNGEncoder = new PNGEncoder();
		
		private static var _history:SessionStateLog;
		
		/**
		 * Contains the session history.
		 */
		public static function get history():SessionStateLog
		{
			if (!_history)
				_history = new SessionStateLog(WeaveAPI.globalHashMap, HISTORY_SYNC_DELAY);
			return _history;
		}
		
		/**
		 * Creates a thumbnail to be included in a WeaveArchive.
		 */
		public static function createScreenshot(thumbnailSize:int = 0):ByteArray
		{
			var application:Object = WeaveAPI.topLevelApplication;
			
			// HACK
			var component:IFlexDisplayObject = application.hasOwnProperty('visApp') ? application['visApp'] : application as IFlexDisplayObject;
			
			var bitmapData:BitmapData = BitmapUtils.getBitmapDataFromComponent(component, thumbnailSize, thumbnailSize);
			return _pngEncoder.encode(bitmapData);
		}
		
		/**
		 * Updates the local embedded thumbnail and screenshot files.
		 */
		public static function updateLocalThumbnailAndScreenshot(saveScreenshot:Boolean):void
		{
			try
			{
				WeaveAPI.URLRequestUtils.saveLocalFile(ARCHIVE_THUMBNAIL_PNG, createScreenshot(THUMBNAIL_SIZE));
				
				if (saveScreenshot)
					WeaveAPI.URLRequestUtils.saveLocalFile(ARCHIVE_SCREENSHOT_PNG, createScreenshot());
				else
					WeaveAPI.URLRequestUtils.removeLocalFile(ARCHIVE_SCREENSHOT_PNG);
			}
			catch (e:SecurityError)
			{
				WeaveAPI.URLRequestUtils.removeLocalFile(ARCHIVE_THUMBNAIL_PNG);
				WeaveAPI.URLRequestUtils.removeLocalFile(ARCHIVE_SCREENSHOT_PNG);
				WeaveAPI.ErrorManager.reportError(e, "Unable to create screenshot due to lack of permissive policy file for embedded image. " + e.message);
			}
		}
		
		/**
		 * This function will create an object that can be saved to a file and recalled later with loadWeaveFileContent().
		 */
		public static function createWeaveFileContent(saveScreenshot:Boolean=false, pluginList:Array = null):ByteArray
		{
			var output:WeaveArchive = new WeaveArchive();
			
			// thumbnail should go first in the stream because we will often just want to extract the thumbnail and nothing else.
			updateLocalThumbnailAndScreenshot(saveScreenshot);
			
			// embedded files
			for each (var fileName:String in WeaveAPI.URLRequestUtils.getLocalFileNames())
				output.files[fileName] = WeaveAPI.URLRequestUtils.getLocalFile(fileName);
			
			if (pluginList)
				output.objects[ARCHIVE_PLUGINS_AMF] = pluginList;
			
			// session history
			var _history:Object = history.getSessionState();
			output.objects[ARCHIVE_HISTORY_AMF] = _history;
			
			return output.serialize();
		}
	}
}
