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
	public class EntityMetadata
	{
		public static const CONNECTION:String = "connection";
		public static const SQLQUERY:String = "sqlQuery";
		public static const SQLPARAMS:String = "sqlParams";
		public static const SQLRESULT:String = "sqlResult";
		public static const SCHEMA:String = "schema";
		public static const TABLEPREFIX:String = "tablePrefix";
		public static const IMPORTNOTES:String = "importNotes";
		
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

		public static function mergeObjects(a:Object, b:Object):Object
		{
			var result:Object = {}
			for each (var obj:Object in [a, b])
			for (var property:Object in obj)
				result[property] = obj[property];
			return result;
		}
		public static function diffObjects(old:Object, fresh:Object):Object
		{
			var diff:Object = {};
			for (var property:String in mergeObjects(old, fresh))
				if (old[property] != fresh[property])
					diff[property] = fresh[property];
			return diff;
		}
	}
}
