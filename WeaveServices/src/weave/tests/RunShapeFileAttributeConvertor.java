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
		String dbms = SQLUtils.SQLSERVER;
		String ip = "localhost";
		String port = "1433";
		String database = "SQLSERVER_DEV";
		String user = "root";
		String pass = "<PASSWORD>";
		String sqlSchema = "shapes5";
		String sqlTable = "test_table";
		String fileName = "st99_d00.dbf";
		String[] nullValues={};
		
		Connection conn = SQLUtils.getConnection(SQLUtils.getConnectString(dbms, ip, port, database, user, pass));
		DBFUtils.storeAttributes(new File[]{ new File(fileName) }, conn, sqlSchema, sqlTable, true, nullValues);
	}

}
