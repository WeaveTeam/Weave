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

import java.sql.Connection;
import java.util.Arrays;
import java.util.Map;

import weave.utils.MapUtils;
import weave.utils.SQLUtils;

public class SQLServerTest 
{
	public static void main(String[] args)
	{
		try
		{
			String connectString = SQLUtils.getConnectString(SQLUtils.SQLSERVER, "localhost", "1433", "<INSTNANCE_NAME>", "<USERNAME>", "<PASSWORD>");
			Connection conn = SQLUtils.getConnection(connectString);
			Map<String, Object> valueMap = MapUtils.fromPairs(
				"First Name", "fName",
				"Last Name", "lName",
				"Age", 22,
				"Grade", "A"
			);
			String[] columnNames = {"First Name", "Last Name", "Age", "Grade"};
			String[] columnTypes = {"VARCHAR(20)", "VARCHAR(20)", "int", "VARCHAR(5)"};
			
			SQLUtils.createTable(conn, "dbo", "testTable2", Arrays.asList(columnNames), Arrays.asList(columnTypes), null);
			SQLUtils.insertRow(conn, "dbo", "testTable2", valueMap);
		}
		catch (Exception e)
		{
			System.out.println(e);
		}
		
		
	}
}
