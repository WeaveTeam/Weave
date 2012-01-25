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
	import flash.utils.getQualifiedClassName;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipFile;
	import nochump.util.zip.ZipOutput;

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
		 */
		public const objects:Object = new OrderedHashMap();
		
		/**
		 * This is a dynamic object containing all the amf objects stored in the archive.
		 */
		public const files:Object = new OrderedHashMap();
		
		private static const FOLDER_AMF:String = "weave-amf"; // folder used for amf-encoded objects
		private static const FOLDER_FILES:String = "weave-files"; // folder used for raw files
		
		/**
		 * @private
		 */		
		private function _readArchive(fileData:ByteArray):void
		{
			var zip:ZipFile = new ZipFile(fileData);
			for (var i:int = 0; i < zip.entries.length; i++)
			{
				var entry:ZipEntry = zip.entries[i];
				var path:Array = entry.name.split('/');
				if (path[0] == FOLDER_FILES)
					files[path[1]] = zip.getInput(entry);
				if (path[0] == FOLDER_AMF)
					objects[path[1]] = zip.getInput(entry).readObject();
			}
		}
		
		/**
		 * @private
		 */		
		private function _addZipEntry(zipOut:ZipOutput, fileName:String, fileData:ByteArray):void
		{
			var ze:ZipEntry = new ZipEntry(fileName);
			zipOut.putNextEntry(ze);
			zipOut.write(fileData);
			zipOut.closeEntry();
		}
		
		/**
		 * This function will create a ByteArray containing the objects that have been specified with setObject().
		 * @param contentType A String describing the type of content contained in the objects.
		 * @return A ByteArray in the Weave file format.
		 */
		public function serialize():ByteArray
		{
			var i:int;
			var name:String;
			var zipOut:ZipOutput = new ZipOutput();
			for (name in files)
			{
				_addZipEntry(zipOut, FOLDER_FILES + '/' + name, files[name]);
			}
			for (name in objects)
			{
				var amf:ByteArray = new ByteArray();
				amf.writeObject(objects[name]);
				_addZipEntry(zipOut, FOLDER_AMF + '/' + name, amf);
			}
			zipOut.comment = getQualifiedClassName(this);
			zipOut.finish();
			
			return zipOut.byteArray;
		}
	}
}

import flash.utils.Proxy;
import flash.utils.flash_proxy;

/**
 * The names and values in this object are enumerated in the order they were added.
 */
internal class OrderedHashMap extends Proxy
{
	private var names:Array = [];
	private var values:Array = [];
	
	override flash_proxy function getProperty(name:*):*
	{
		var i:int = names.indexOf(String(name));
		if (i >= 0)
			return values[i];
		return null;
	}
	override flash_proxy function setProperty(name:*, value:*):void
	{
		flash_proxy::deleteProperty(name);
		
		names.push(String(name));
		values.push(value);
	}
	override flash_proxy function deleteProperty(name:*):Boolean
	{
		var i:int = names.indexOf(String(name));
		if (i >= 0)
		{
			names.splice(i, 1);
			values.splice(i, 1);
		}
		return i >= 0;
	}
	override flash_proxy function nextNameIndex(index:int):int
	{
		if (index < names.length)
			return index + 1;
		return 0;
	}
	override flash_proxy function nextName(index:int):String
	{
		return names[index - 1];
	}
	override flash_proxy function nextValue(index:int):*
	{
		return values[index - 1];
	}
}
