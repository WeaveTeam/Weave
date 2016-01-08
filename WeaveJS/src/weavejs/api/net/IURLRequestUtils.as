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

package weavejs.api.net
{
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.util.WeavePromise;

	/**
	 * An interface for GET and POST URL requests.
	 * 
	 * @author adufilie
	 */
	public interface IURLRequestUtils
	{
		/**
		 * Makes a URL request.
		 * @param method Either "get" or "post"
		 * @param url The URL
		 * @param requestHeaders Maps request header names to values
		 * @param data Specified if method is "post"
		 * @param responseType Can be "text", "arraybuffer", "blob", "json", or "document"
		 * @return A WeavePromise
		 */
		function request(relevantContext:Object, method:String, url:String, requestHeaders:Object, data:String, responseType:String):WeavePromise;
		
		/**
		 * This will save a file in memory so that it can be accessed later via getURL().
		 * @param name The file name.
		 * @param byteArray The file content in a Uint8Array.
		 * @return The URL at which the file can be accessed later via getURL(). This will be the string "local://" followed by the filename.
		 */
		function saveLocalFile(weaveRoot:ILinkableHashMap, name:String, byteArray:/*Uint8*/Array):String;
		
		/**
		 * Retrieves file content previously saved via saveLocalFile().
		 * @param The file name that was passed to saveLocalFile().
		 * @return The file content in a Uint8Array.
		 */
		function getLocalFile(weaveRoot:ILinkableHashMap, name:String):/*Uint8*/Array;
		
		/**
		 * Removes a local file that was previously added via saveLocalFile().
		 * @param name The file name which was passed to saveLocalFile().
		 */
		function removeLocalFile(weaveRoot:ILinkableHashMap, name:String):void;
		
		/**
		 * Gets a list of names of files saved via saveLocalFile().
		 * @return An Array of file names.
		 */
		function getLocalFileNames(weaveRoot:ILinkableHashMap):Array;
	}
}
