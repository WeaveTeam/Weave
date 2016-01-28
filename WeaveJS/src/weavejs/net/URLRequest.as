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

package weavejs.net
{
	public class URLRequest
	{
		public function URLRequest(url:String = null)
		{
			this.url = url;
		}
		
		/**
		 * Either "get" or "post"
		 * @default "get"
		 */
		public var method:String = RequestMethod.GET;
		
		/**
		 * The URL
		 */
		public var url:String;
		
		/**
		 * Specified if method is "post"
		 */
		public var data:String;
		
		/**
		 * Maps request header names to values
		 */
		public var requestHeaders:Object;
		
		/**
		 * Can be one of the constants defined in the ResponseType class.
		 * @see weavejs.net.ResponseType
		 */
		public var responseType:String = ResponseType.UINT8ARRAY;
		
		/**
		 * Specifies the mimeType for the Data URI returned when responseType === "datauri".
		 */
		public var mimeType:String;
	}
}
