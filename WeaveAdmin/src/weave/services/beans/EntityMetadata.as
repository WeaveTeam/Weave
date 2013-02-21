/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.services.beans
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
				ColumnMetadata.MIN,
				ColumnMetadata.MAX,
				'year'
			];
		}
		
		public static function getSuggestedPrivatePropertyNames():Array
		{
			return [
				"connection",
				"sqlSchema",
				"sqlTable",
				"sqlColumn",
				"sqlQuery",
				"sqlParams",
				"sqlResult",
				"importMethod",
				"sqlKeyColumn",
				"sqlTablePrefix",
				"fileName",
				"keyColumn"
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
