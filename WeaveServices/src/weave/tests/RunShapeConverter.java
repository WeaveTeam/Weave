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

import java.sql.Connection;
import java.util.Vector;

import weave.geometrystream.GeometryStreamConverter;
import weave.geometrystream.SHPGeometryStreamUtils;
import weave.geometrystream.SQLGeometryStreamDestination;
import weave.utils.SQLUtils;

public class RunShapeConverter
{
	/**
	 * Usage: main( attribute ... -- shapeFile ... )
	 * @param args
	 */
	public static void main(String[] args) throws Exception
	{
		int i = 0;

		// get list of attributes
		Vector<String> attributes = new Vector<String>();
		for (; i < args.length; i++)
		{
			// check for separator
			if (args[i].equalsIgnoreCase("--"))
				break;

			attributes.add(args[i]);
			System.out.println("attr: " + args[i]);
		}

		i++; // skip over separator
		
		// get list of shapefiles
		Vector<String> files = new Vector<String>();
		for (; i < args.length; i++)
		{
			files.add(args[i]);
			System.out.println("file: " + args[i]);
		}

		String dbms = SQLUtils.SQLSERVER;
		String ip = "localhost";
		String port = "1433";
		String database = "SQLSERVER_DEV";
		String user = "root";
		String pass = "<PASSWORD>";
		String sqlSchema = "shp_convert";
		String sqlTablePrefix = "shptest";
		
		Connection conn = SQLUtils.getConnection(SQLUtils.getDriver(dbms), SQLUtils.getConnectString(dbms, ip, port, database, user, pass));
		GeometryStreamConverter converter = new GeometryStreamConverter(new SQLGeometryStreamDestination(conn, sqlSchema, sqlTablePrefix, true));
		for (String file : files)
			SHPGeometryStreamUtils.convertShapefile(converter, file, attributes);
		converter.flushAndCommitAll();
	}
}
