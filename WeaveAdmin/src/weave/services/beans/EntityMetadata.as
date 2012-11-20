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
		
		protected var _privateMetadata:Object = {};
		protected var _publicMetadata:Object = {};
		
		public function get privateMetadata():Object { return _privateMetadata; }
		public function get publicMetadata():Object { return _publicMetadata; }
		
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

		private function outputDiff(oldObj:Object, newObj:Object, output:Object):void
		{
			var name:String;
			for (name in oldObj)
				if (oldObj[name] != newObj[name])
					output[name] = newObj[name];
			for (name in newObj)
				if (oldObj[name] != newObj[name])
					output[name] = newObj[name];
		}
		
		public function getDiff(newPrivateMetadata:Object, newPublicMetadata:Object):EntityMetadata
		{
			var diff:EntityMetadata = new EntityMetadata();
			outputDiff(_privateMetadata, newPrivateMetadata, diff._privateMetadata);
			outputDiff(_publicMetadata, newPublicMetadata, diff._publicMetadata);
			return diff;
		}
	}
}
