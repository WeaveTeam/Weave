/* ***** BEGIN LICENSE BLOCK *****
* Version: MPL 1.1/GPL 2.0/LGPL 2.1
*
* The contents of this file are subject to the Mozilla Public License Version
* 1.1 (the "License"); you may not use this file except in compliance with
* the License. You may obtain a copy of the License at
* http://www.mozilla.org/MPL/
*
* Software distributed under the License is distributed on an "AS IS" basis,
* WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
* for the specific language governing rights and limitations under the
* License.
*
* The Original Code is the Weave API.
*
* The Initial Developer of the Original Code is the Institute for Visualization
* and Perception Research at the University of Massachusetts Lowell.
* Portions created by the Initial Developer are Copyright (C) 2008-2011
* the Initial Developer. All Rights Reserved.
*
* Contributor(s):
*
* Alternatively, the contents of this file may be used under the terms of
* either the GNU General Public License Version 2 or later (the "GPL"), or
* the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
* in which case the provisions of the GPL or the LGPL are applicable instead
* of those above. If you wish to allow use of your version of this file only
* under the terms of either the GPL or the LGPL, and not to allow others to
* use your version of this file under the terms of the MPL, indicate your
* decision by deleting the provisions above and replace them with the notice
* and other provisions required by the GPL or the LGPL. If you do not delete
* the provisions above, a recipient may use your version of this file under
* the terms of any one of the MPL, the GPL or the LGPL.
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
		 * @param content The content of the file.
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
			try
			{
				var header:Object = data.readObject();
				if (header != WEAVE_FILE_HEADER)
					throw new Error("Unsupported file format");
				
				var body:ByteArray = new ByteArray();
				data.readBytes(body);
				body.uncompress();
				
				var content:Object = body.readObject();
				return content;
			}
			catch (e:Error) { }
			
			throw new Error("Unknown file format");
		}
	}
}
