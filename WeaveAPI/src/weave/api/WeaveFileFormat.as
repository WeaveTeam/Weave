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
	 * This is a pair of static functions for reading and writing files in the Weave file format.
	 * The Weave file format consists of a header followed by a compressed AMF3-serialized object.
	 * 
	 * @author adufilie
	 */
	public class WeaveFileFormat
	{
		/**
		 * This string is used in the header of a Weave file.
		 */
		private static const WEAVE_FILE_HEADER:String = "Weave Compressed AMF3";
		
		/**
		 * This function will create a ByteArray that contains the specified content in the Weave file format.
		 * @param content The content to be encoded.
		 * @return A ByteArray that contains the specified content encoded in the Weave file format.
		 */
		public static function createFile(content:Object):ByteArray
		{
			var body:ByteArray = new ByteArray();
			body.writeObject(content);
			body.compress();
			
			var output:ByteArray = new ByteArray();
			output.writeObject(WEAVE_FILE_HEADER);
			output.writeBytes(body);
			return output;
		}
		
		/**
		 * This function will read the content from a Weave file.  An Error will be thrown if the given data is not in the Weave file format.
		 * @param data The bytes of a Weave file.
		 * @return The decoded content of the Weave file.
		 */
		public static function readFile(data:ByteArray):Object
		{
			var err_msg:String = "Unknown file format";
			try
			{
				var header:Object = data.readObject();
				if (header == WEAVE_FILE_HEADER)
				{
					var body:ByteArray = new ByteArray();
					data.readBytes(body);
					body.uncompress();
					
					var content:Object = body.readObject();
					return content;
				}
				else
				{
					err_msg = "Unsupported file format";
				}
			}
			catch (e:Error) { }
			
			throw new Error(err_msg);
		}
	}
}
