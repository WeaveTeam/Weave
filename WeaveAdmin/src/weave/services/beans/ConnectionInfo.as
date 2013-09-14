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
	public class ConnectionInfo
	{
		[Bindable] public var name:String = "";
		[Bindable] public var pass:String = "";
		[Bindable] public var folderName:String = "" ;
		[Bindable] public var connectString:String = "" ;
		[Bindable] public var is_superuser:Boolean = false;
		
		public function ConnectionInfo(obj:Object)
		{
			for (var name:String in obj)
				if (this.hasOwnProperty(name))
					this[name] = obj[name];
		}

		/**
		 * This is a list of supported DBMS values.
		 */
		public static function get dbmsList():Array
		{
			return [MYSQL, POSTGRESQL, SQLSERVER, ORACLE];
		}
		
		public static const MYSQL:String = 'MySQL';
		public static const POSTGRESQL:String = 'PostGreSQL';
		public static const SQLSERVER:String = 'Microsoft SQL Server';
		public static const ORACLE:String = 'Oracle';
		
		/**
		 * This function will get the default port for a DBMS.
		 * @param dbms A supported DBMS.
		 * @return The default port for the dbms.
		 */
		public static function getDefaultPort(dbms:String):int
		{
			switch (dbms)
			{
				case MYSQL: return 3306;
				case POSTGRESQL: return 5432;
				case SQLSERVER: return 1433;
				case ORACLE: return 1521;
			}
			return 0;
		}
	}
}