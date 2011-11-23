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
	import mx.utils.ObjectUtil;

	public class ConnectionInfo
	{
		[Bindable] public var name:String = "";
		[Bindable] public var dbms:String = "";
		[Bindable] public var ip:String = "";
		[Bindable] public var port:String = "";
		[Bindable] public var database:String = "";
		[Bindable] public var user:String = "";
		[Bindable] public var pass:String = "";
		[Bindable] public var folderName:String = "" ;
		[Bindable] public var is_superuser:Boolean = false;
		
		public function ConnectionInfo(obj:Object)
		{
			for (var name:String in obj)
				if (this.hasOwnProperty(name))
					this[name] = obj[name];

			if (ip == '')
				ip = 'localhost';
			
			if (port == '')
				port = String(getDefaultPort(dbms));
		}

		/**
		 * This is a list of supported DBMS values.
		 */
		public static function get dbmsList():Array
		{
			return ['MySQL', 'PostGreSQL', 'Microsoft SQL Server', 'Oracle'];
		}
		
		/**
		 * This function will get the default port for a DBMS.
		 * @param dbms A supported DBMS.
		 * @return The default port for the dbms.
		 */
		public static function getDefaultPort(dbms:String):int
		{
			var list:Array = dbmsList;
			for (var i:int = 0; i < list.length; i++)
				if (ObjectUtil.stringCompare(list[i], dbms, true) == 0)
					return defaultPortList[i];
			return 0;
		}
		
		private static const defaultPortList:Array = [3306, 5432, 1433, 1521]; // corresponding to the database products in dbmsList
	}
}