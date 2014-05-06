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

package weave.api.services.beans
{
	import weave.api.data.ColumnMetadata;

	public class EntityMetadata
	{
		public static function getSuggestedPublicPropertyNames():Array
		{
			return [
				ColumnMetadata.TITLE,
				ColumnMetadata.NUMBER,
				ColumnMetadata.STRING,
				ColumnMetadata.KEY_TYPE,
				ColumnMetadata.DATA_TYPE,
				ColumnMetadata.PROJECTION,
				ColumnMetadata.DATE_FORMAT,
				ColumnMetadata.MIN,
				ColumnMetadata.MAX,
				'year'
			];
		}
		
		public static function getSuggestedPrivatePropertyNames():Array
		{
			return [
				"connection",
				"sqlQuery",
				"sqlParams",
				"sqlTablePrefix",
				"importMethod",
				"fileName",
				"keyColumn",
				"sqlSchema",
				"sqlTable",
				"sqlKeyColumn",
				"sqlColumn"
			];
		}
		
		public var privateMetadata:Object = {};
		public var publicMetadata:Object = {};
		
		private function objToStr(obj:Object):String
		{
			var str:String = '';
			for (var name:String in obj)
			{
				if (str)
					str += '; ';
				str += name + ': ' + obj[name];
			}
			return '{' + str + '}';
		}
		
		public function toString():String
		{
			return objToStr({'publicMetadata': objToStr(publicMetadata), 'privateMetadata': objToStr(privateMetadata)});
		}
	}
}
