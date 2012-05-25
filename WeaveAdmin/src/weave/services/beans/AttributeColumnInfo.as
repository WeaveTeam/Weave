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
		
		public function AttributeColumnInfo(o:Object)
		{
			this.id = o.id;
                        this.entity_type = o.type
			this.privateMetadata = o.privateMetadata;
			this.publicMetadata = o.publicMetadata;
	
			// replace nulls with empty strings
			for each (var metadata:Object in [privateMetadata, publicMetadata])
				for (var name:String in metadata)
					if (metadata[name] == null)
						metadata[name] = '';
		}
		public function deepcopy():AttributeColumnInfo
                {
                    var tmpobj:Object = {};
                    tmpobj.id = this.id;
                    tmpobj.entity_type = this.entity_type;
                    tmpobj.privateMetadata = {};
                    tmpobj.publicMetadata = {};
                    var prop:String;
                    /* Probably a cleaner way to do this. */
                    for (prop in this.privateMetadata)
                    {
                        tmpobj.privateMetadata[prop] = this.privateMetadata[prop];
                    }
                    for (prop in this.publicMetadata)
                    {
                        tmpobj.publicMetadata[prop] = this.publicMetadata[prop];
                    }
                    var result:AttributeColumnInfo = new AttributeColumnInfo(tmpobj) 
                    return result; 
                }
                static public function splitObject(obj:Object):Array /* Returns an array containing [publicMeta, privateMeta] */
                {
                    var pub:Object = {};
                    var priv:Object = {};
                    for each (var prop:String in obj)
                        if (isPrivate(prop))
                            priv[prop] = obj[prop];
                        else
                            pub[prop] = obj[prop];
                    return [pub, priv];         
                }
                static public function mergeObjects(a:Object, b:Object):Object
                {
                    var result:Object = {}
                    for each (var obj:Object in [a, b])
                        for each (var property:Object in obj)
                            result[property] = obj[property];
                    return result;
                }
                static public function diffObjects(old:Object, fresh:Object):Object
                {
                    var diff:Object = {};
                    for each (var property:String in mergeObjects(old, fresh))
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
