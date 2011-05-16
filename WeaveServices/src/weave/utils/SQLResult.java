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

package weave.utils;

import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.LinkedList;

/**
 * This is a lightweight object that holds the data from a ResultSet.
 * 
 * @author Andy Dufilie
 */
public class SQLResult
{
	public SQLResult(ResultSet rs) throws SQLException
	{
		ResultSetMetaData metadata = rs.getMetaData();
		int n = metadata.getColumnCount();
		
		columnNames = new String[n];
		columnTypes = new int[n];
		for (int i = 0; i < n; i++)
		{
			columnNames[i] = metadata.getColumnName(i + 1);
			columnTypes[i] = metadata.getColumnType(i + 1);
		}
		
		LinkedList<Object[]> linkedRows = new LinkedList<Object[]>();
		while (rs.next())
		{
			Object[] row = new Object[n];
			for (int i = 0; i < n; i++)
				row[i] = rs.getObject(i + 1);
			linkedRows.add(row);
		}
		rows = linkedRows.toArray(new Object[linkedRows.size()][]);
	}
	
	public String[] columnNames;
	public int[] columnTypes;
	public Object[][] rows;
}
