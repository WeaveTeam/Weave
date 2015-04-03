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

package weave.services.beans
{
	public class ConnectionInfo
	{
		[Bindable] public var name:String = "";
		[Bindable] public var pass:String = "";
		[Bindable] public var folderName:String = "" ;
		[Bindable] public var connectString:String = "" ;
		[Bindable] public var is_superuser:Boolean = false;
		
		/**
		 * This is a list of supported DBMS values.
		 */
		public static function get dbmsList():Array
		{
			return [MYSQL, SQLITE, POSTGRESQL, SQLSERVER, ORACLE];
		}
		
		public static const MYSQL:String = 'MySQL';
		public static const SQLITE:String = 'SQLite';
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
				case SQLITE: return 0;
				case POSTGRESQL: return 5432;
				case SQLSERVER: return 1433;
				case ORACLE: return 1521;
			}
			return 0;
		}
	}
}