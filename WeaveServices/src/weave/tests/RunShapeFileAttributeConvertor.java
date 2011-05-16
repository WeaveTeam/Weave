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
package weave.tests;

import java.io.File;
import java.sql.Connection;

import weave.utils.SQLUtils;
import weave.utils.DBFUtils;

public class RunShapeFileAttributeConvertor  {

	/**
	 * @param args
	 */
	public static void main(String[] args) throws Exception{
		// TODO Auto-generated method stub
		
		System.out.println(args.toString());
		String dbms = "MySQL";
		String ip = "129.63.8.210";
		String port = "3306";
		String database = "";
		String user = "root";
		String pass = "PASSWORD";
		String sqlSchema = "shapes5";
		String sqlTable = "test_table";
		String fileName = args[0];
		String[] nullValues={};
		
		Connection conn = SQLUtils.getConnection(SQLUtils.getDriver(dbms), SQLUtils.getConnectString(dbms, ip, port, database, user, pass));
		DBFUtils.storeAttributes(new File[]{ new File(fileName) }, conn, sqlSchema, sqlTable, true, nullValues);
		conn.commit();
		

	}

}
