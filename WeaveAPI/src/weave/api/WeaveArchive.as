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

package weave.api
{
	import flash.utils.ByteArray;
	
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
	}
}
