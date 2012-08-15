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
	public class AttributeColumnInfo
	{
                static public const CONNECTION:String = "connection";
                static public const SQLQUERY:String = "sqlQuery";
                static public const SQLPARAMS:String = "sqlParams";
                static public const SQLRESULT:String = "sqlResult";
                static public const SCHEMA:String = "schema";
                static public const TABLEPREFIX:String = "tablePrefix";
                static public const IMPORTNOTES:String = "importNotes";
                static public function isPrivate(prop:String):Boolean
                {
                    return prop in [CONNECTION, SQLQUERY, SQLPARAMS, SQLRESULT, SCHEMA, TABLEPREFIX, IMPORTNOTES];
                }
                public static const TABLE:int = 0;
                public static const COLUMN:int = 1;
                public static const TAG:int = 2;
		public var id:int;
		public var entity_type:int;
		public var privateMetadata:Object;
		public var publicMetadata:Object;
		
		public function AttributeColumnInfo(o:Object = null)
		{
                        if (o == null) return;
			this.id = o.id;
                        this.entity_type = o.type;
			this.privateMetadata = o.privateMetadata;
			this.publicMetadata = o.publicMetadata;
	
			// replace nulls with empty strings
			for each (var metadata:Object in [privateMetadata, publicMetadata])
				for (var name:String in metadata)
					if (metadata[name] == null)
						metadata[name] = '';
		}
                static public function mergeObjects(a:Object, b:Object):Object
                {
                    var result:Object = {}
                    for each (var obj:Object in [a, b])
                        for (var property:Object in obj)
                            result[property] = obj[property];
                    return result;
                }
                static public function diffObjects(old:Object, fresh:Object):Object
                {
                    var diff:Object = {};
                    for (var property:String in mergeObjects(old, fresh))
                        if (old[property] != fresh[property])
                            diff[property] = fresh[property];
                    return diff;
                }
		public function getAllMetadata():Object
		{
                    return mergeObjects(privateMetadata, publicMetadata);
		}
	}
}
