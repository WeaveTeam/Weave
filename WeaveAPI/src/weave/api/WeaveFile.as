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

	/**
	 * This is a wrapper around a ByteArray for reading and writing data in the Weave file format.
	 * 
	 * @author adufilie
	 */
	public class WeaveFile
	{
		/**
		 * @param contentType A String that identifies what is contained in the file.
		 * @param input An optional file input to be parsed.  If the contentType of the input file is different from the specified contentType parameter, an error will be thrown.
		 */		
		public function WeaveFile(input:ByteArray = null)
		{
			if (input)
				_readFile(input);
		}
		
		/**
		 * This string is used in the header of a Weave file.
		 */
		private static const WEAVE_FILE_HEADER:String = "Weave Compressed AMF3";
		
		/**
		 * This is a String that can be used to describe what is contained in the file.
		 */
		private var _contentType:String = null;
		
		/**
		 * This is a list of names corresponding to objects in the file.
		 */
		private var _objectNames:Array = [];
		
		/**
		 * This is a list of objects in the file.
		 */		
		private var _objects:Array = [];
		
		/**
		 * This function reads the contents of 
		 * The file format consists of an AMF3-serialized String header followed by a compressed AMF3 stream.
		 * The compressed stream contains a series of objects as follows:
		 *     contentType:String, objectNames:Array, obj0:Object, obj1:Object, obj2:Object, ...
		 *  
		 * @param input The contents of a Weave file.
		 */		
		private function _readFile(input:ByteArray):void
		{
			// the header is encoded in AMF3
			var header:Object = null;
			try {
				header = input.readObject();
			} catch (e:Error) { }

			if (header != WEAVE_FILE_HEADER)
				throw new Error("Unsupported file format");
			
			// everything after the header is the body, a compressed AMF3 stream
			try
			{
				// uncompress the AMF3 stream
				var body:ByteArray = new ByteArray();
				input.readBytes(body);
				body.uncompress();
				
				// read the objects from the AMF3 stream
				_contentType = body.readObject() as String;
				_objectNames = body.readObject() as Array;
				_objects = [];
				for (var i:int = 0; i < _objectNames.length; i++)
					_objects.push(body.readObject());
			}
			catch (e:Error)
			{
				throw new Error("Corrupt file");
			}
		}
			
		/**
		 * This function will create a ByteArray containing the objects that have been specified with setObject().
		 * @param contentType A String describing the type of content contained in the objects.
		 * @return A ByteArray in the Weave file format.
		 */
		public function serialize():ByteArray
		{
			var output:ByteArray = new ByteArray();
			
			// write header
			output.writeObject(WEAVE_FILE_HEADER);
			
			// prepare uncompressed body
			var body:ByteArray = new ByteArray();
			body.writeObject(_contentType);
			body.writeObject(_objectNames);
			for (var i:int = 0; i < _objectNames.length; i++)
				body.writeObject(_objects[i]);
			
			// write compressed body
			body.compress();
			output.writeBytes(body);
			
			return output;
		}

		/**
		 * Returns a String that identifies what is contained in the file.
		 * @return The content type.
		 */
		public function getContentType():String
		{
			return _contentType;
		}

		/**
		 * Use this function to specify the content type prior to calling serialize().
		 * @param contentType A String that identifies what is contained in the file.
		 */		
		public function setContentType(contentType:String):void
		{
			_contentType = contentType;
		}

		/**
		 * This function will retrieve the first object with the specified name.
		 * @param name The name which identifies an object.
		 * @return The object with the given name.
		 */		
		public function getObject(name:String):Object
		{
			var index:int = _objectNames.indexOf(name);
			if (index < 0)
				return null;
			return _objects[index];
		}
		
		/**
		 * This function will remove any existing object under the specified name and append the new one to the end of the file.
		 * @param name The name which identifies the object.
		 * @param object The object to append to the end of the file.
		 */
		public function setObject(name:String, object:Object):void
		{
			deleteObject(name);
			
			_objectNames.push(name);
			_objects.push(object);
		}
		
		/**
		 * This function will remove any existing object under the specified name.
		 * @param name The name which identifies the object to delete.
		 */
		public function deleteObject(name:String):void
		{
			for (var i:int = _objectNames.length - 1; i >= 0; i--)
			{
				if (_objectNames[i] == name)
				{
					_objectNames.splice(i, 1);
					_objects.splice(i, 1);
				}
			}
		}
	}
}
