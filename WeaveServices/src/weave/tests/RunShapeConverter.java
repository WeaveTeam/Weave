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
		
		Connection conn = SQLUtils.getConnection(SQLUtils.getConnectString(dbms, ip, port, database, user, pass));
		GeometryStreamConverter converter = new GeometryStreamConverter(new SQLGeometryStreamDestination(conn, sqlSchema, sqlTablePrefix, true));
		for (String file : files)
			SHPGeometryStreamUtils.convertShapefile(converter, file, attributes);
		converter.flushAndCommitAll();
	}
}
