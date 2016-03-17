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
	import weavejs.data.AttributeColumnCache;
	import weavejs.net.URLRequest;
	import weavejs.util.BackwardsCompatibility;
	import weavejs.util.JSByteArray;
	import weavejs.util.WeavePromise;
	
	/**
	 * This is an interface for reading and writing data in the Weave file format.
	 * 
	 * @author adufilie
	 */
	public class WeaveArchive
	{
		/**
		 * This must be set externally.
		 */
		public static var JSZip:Class;
		
		/**
		 * @param input A Weave file to decode.
		 */
		public function WeaveArchive(byteArray:/*/Uint8Array/*/Array = null)
		{
			if (byteArray)
				_readArchive(byteArray);
		}
		
		/**
		 * This is a dynamic object containing all the files (ByteArray objects) in the archive.
		 * The property names used in this object must be valid filenames or serialize() will fail.
		 */
		public const files:Object = {};
		
		/**
		 * This is a dynamic object containing all the amf objects stored in the archive.
		 * The property names used in this object must be valid filenames or serialize() will fail.
		 */
		public const objects:Object = {};
		
		private static const FOLDER_AMF:String = "weave-amf"; // folder used for AMF3-encoded objects
		private static const FOLDER_JSON:String = "weave-json"; // folder used for JSON-encoded objects
		private static const FOLDER_FILES:String = "weave-files"; // folder used for raw files
		
		/**
		 * @private
		 */		
		private function _readArchive(byteArray:/*/Uint8Array/*/Array):void
		{
			var zip:Object = new JSZip(byteArray);
			for (var filePath:String in zip.files)
			{
				var fileName:String = filePath.substr(filePath.indexOf('/') + 1);
				var file:Object = zip.files[filePath];
				if (file.dir)
					continue;
				if (filePath.indexOf(FOLDER_JSON + '/') == 0)
				{
					objects[fileName] = JSON.parse(file.asText());
				}
				else if (filePath.indexOf(FOLDER_AMF + '/') == 0)
				{
					var amf:Object = new JSByteArray(file.asUint8Array());
					objects[fileName] = amf.readObject();
				}
				else
				{
					files[fileName] = file.asUint8Array();
				}
			}
		}
		
		/**
		 * This function will create a ByteArray containing the objects that have been specified with setObject().
		 * @param contentType A String describing the type of content contained in the objects.
		 * @return A Uint8Array in the Weave file format.
		 */
		public function serialize(readableJSON:Boolean = true):/*/Uint8Array/*/Array
		{
			var zip:Object = new JSZip();
			var name:String;
			var folder:Object;
			
			folder = zip.folder(FOLDER_FILES);
			for (name in files)
				folder.file(name, files[name]);
			
			folder = zip.folder(FOLDER_JSON);
			for (name in objects)
				folder.file(name, JSON.stringify(objects[name], null, readableJSON && '\t'));
			
			return zip.generate({type: 'uint8array'});
		}
		
//		public static const HISTORY_SYNC_DELAY:int = 100;
//		public static const THUMBNAIL_SIZE:int = 200;
//		public static const ARCHIVE_THUMBNAIL_PNG:String = "thumbnail.png";
//		public static const ARCHIVE_SCREENSHOT_PNG:String = "screenshot.png";
//		public static const ARCHIVE_URL_CACHE_AMF:String = "url-cache.amf";
//		public static const ARCHIVE_URL_CACHE_JSON:String = "url-cache.json";
		public static const ARCHIVE_HISTORY_AMF:String = "history.amf";
		public static const ARCHIVE_HISTORY_JSON:String = "history.json";
		public static const ARCHIVE_COLUMN_CACHE_AMF:String = "column-cache.amf";
		public static const ARCHIVE_COLUMN_CACHE_JSON:String = "column-cache.json";
		
		/**
		 * Loads a WeaveArchive from file content.
		 */
		public static function loadUrl(weave:Weave, fileUrl:String):WeavePromise
		{
			return new WeavePromise(weave.root).setResult(
				WeaveAPI.URLRequestUtils.request(weave.root, new URLRequest(fileUrl))
					.then(loadFileContent.bind(WeaveArchive, weave))
			);
		}
		
		/**
		 * Loads a WeaveArchive from file content.
		 */
		public static function loadFileContent(weave:Weave, fileContent:/*/Uint8Array/*/Array):void
		{
			var archive:WeaveArchive = new WeaveArchive(fileContent);
			
			var historyJSON:Object = archive.objects[ARCHIVE_HISTORY_JSON];
			var historyAMF:Object = archive.objects[ARCHIVE_HISTORY_AMF];
			if (historyJSON)
			{
				weave.history.setSessionState(historyJSON);
			}
			else if (historyAMF)
			{
				weave.history.setSessionState(BackwardsCompatibility.updateSessionState(historyAMF));
			}
			else
			{
				throw new Error("No session history found");
			}
			
			var columnCache:Object = archive.objects[ARCHIVE_COLUMN_CACHE_AMF] || archive.objects[ARCHIVE_COLUMN_CACHE_JSON];
			(WeaveAPI.AttributeColumnCache as AttributeColumnCache).restoreCache(weave.root, columnCache);
			
			var fileName:String;
			for (fileName in archive.files)
				WeaveAPI.URLRequestUtils.saveLocalFile(weave.root, fileName, archive.files[fileName]);
			
			// remove files not appearing in archive
			for each (fileName in WeaveAPI.URLRequestUtils.getLocalFileNames(weave.root))
				if (!archive.files[fileName])
					WeaveAPI.URLRequestUtils.removeLocalFile(weave.root, fileName);
		}
		
		/**
		 * This function will create an object that can be saved to a file and recalled later with loadWeaveFileContent().
		 */
		public static function createArchive(weave:Weave/*, saveScreenshot:Boolean=false*/):WeaveArchive
		{
			var archive:WeaveArchive = new WeaveArchive();
			
			// thumbnail should go first in the stream because we will often just want to extract the thumbnail and nothing else.
//			updateLocalThumbnailAndScreenshot(saveScreenshot);
			
			// embedded files
			for each (var fileName:String in WeaveAPI.URLRequestUtils.getLocalFileNames(weave.root))
				archive.files[fileName] = WeaveAPI.URLRequestUtils.getLocalFile(weave.root, fileName);
			
			// session history
			var _history:Object = weave.history.getSessionState();
			archive.objects[ARCHIVE_HISTORY_JSON] = _history;
			
			// TEMPORARY SOLUTION - url cache
//			if (WeaveAPI.URLRequestUtils['saveCache'])
//				archive.objects[ARCHIVE_URL_CACHE_JSON] = WeaveAPI.URLRequestUtils.getCache();
			
			// TEMPORARY SOLUTION - column cache
			var columnCache:Object = WeaveAPI.AttributeColumnCache['map_root_saveCache'].get(weave.root);
			if (columnCache)
				archive.objects[ARCHIVE_COLUMN_CACHE_JSON] = columnCache;
			
			return archive;
		}
	}
}
