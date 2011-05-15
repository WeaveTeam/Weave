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
package org.oicweave.utils;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.geotools.data.shapefile.dbf.DbaseFileHeader;
import org.geotools.data.shapefile.dbf.DbaseFileReader;
import org.oicweave.utils.SQLUtils;

 
/**
 * @author skolman
 * @author adufilie
 */
public class DBFUtils
{
	/**
	 * @param dbfFile A DBF file
	 * @return A list of attribute names in the DBF file
	 */
	public static List<String> getAttributeNames(File dbfFile) throws IOException
	{
		FileInputStream fis = new FileInputStream(dbfFile);
		DbaseFileReader dbfReader = new DbaseFileReader(fis.getChannel(), false, Charset.forName("ISO-8859-1"));
		
		//contains the header columns
		DbaseFileHeader dbfHeader = dbfReader.getHeader();
		
		// get the names from the header
		List<String> names = new Vector<String>();
		int n = dbfHeader.getNumFields();
		for (int i = 0; i < n; i++)
			names.add(dbfHeader.getFieldName(i));

		return names;
	}
	
	/**
	 * @param dbfFile a list of DBF files to merge
	 * @param conn a database connection
	 * @param sqlSchema schema to store table
	 * @param sqlTable table name to store data
	 * @return The number of rows affected after sql INSERT queries
	 * @throws IOException,SQLException
	 */
	public static void storeAttributes(File[] dbfFiles, Connection conn, String sqlSchema, String sqlTable, boolean overwriteTables, String[] nullValues) throws IOException,SQLException
	{
		if (!overwriteTables && SQLUtils.tableExists(conn, sqlSchema, sqlTable))
			throw new SQLException("SQL Tables already exist and overwriteTables is false.");
		
		// read records from each file
		List<String> fieldNames = new Vector<String>(); // order corresponds to fieldTypes order
		List<String> fieldTypes = new Vector<String>(); // order corresponds to fieldNames order
		List<Map<String,Object>> records = new Vector<Map<String,Object>>();
		for (File dbfFile : dbfFiles)
		{
			FileInputStream fis = new FileInputStream(dbfFile);
			DbaseFileReader dbfReader = new DbaseFileReader(fis.getChannel(), false, Charset.forName("ISO-8859-1"));
			DbaseFileHeader dbfHeader = dbfReader.getHeader();
			int numFields = dbfHeader.getNumFields();
			int numRecords = dbfHeader.getNumRecords();
			// keep track of the full set of field names
			for (int col = 0; col < numFields; col++)
			{
				String newFieldName = dbfHeader.getFieldName(col);
				boolean foundFieldName = false;
				for (String fieldName : fieldNames)
					if (fieldName.equals(newFieldName))
						foundFieldName = true;
				if (!foundFieldName)
				{
					fieldNames.add(newFieldName);
					fieldTypes.add(getSQLDataType(dbfHeader, col));
				}
			}
			// append records from this file to the full list of records
			for (int row = 0; row < numRecords; row++)
			{
				Map<String,Object> record = new HashMap<String, Object>();
				Object[] entry = dbfReader.readEntry();
				for (int col = 0; col < numFields; col++){
					Object thisEntry = entry[col];
					for( String value : nullValues )
						if( value.equalsIgnoreCase(entry[col].toString())) 
						{
							thisEntry = null;
							break;
						}
					record.put(dbfHeader.getFieldName(col), thisEntry);
				}
				records.add(record);
			}
			// close the file
			dbfReader.close();
			fis.close();
		}
		
		// begin SQL code
		try
		{
			conn.setAutoCommit(false);
			
			String quotedSchemaTable = SQLUtils.quoteSchemaTable(conn, sqlSchema, sqlTable);
			if (overwriteTables)
				if (SQLUtils.tableExists(conn, sqlSchema, sqlTable))
					SQLUtils.getRowCountFromUpdateQuery(conn, "DROP TABLE IF EXISTS " + quotedSchemaTable);
			
			//Create Table
			fieldNames.add(0, "the_geom_id");
			fieldTypes.add(0, "SERIAL PRIMARY KEY");
			SQLUtils.createTable(conn, sqlSchema, sqlTable, fieldNames, fieldTypes);
			
			//Insert Data
			for (int i = 0; i < records.size(); i++)
			{
				try
				{
					SQLUtils.insertRow(conn, sqlSchema, sqlTable, records.get(i));
				}
				catch (SQLException e)
				{
					System.out.println(String.format("Insert failed on row %s: %s", i, records.get(i)));
					throw e;
				}
			}
		}
		finally
		{
			conn.setAutoCommit(true);
		}
	}
	
	//returns a string format of the SQL Datatype of the column using the getFieldType function from DBaseFileHeader
	private static String getSQLDataType(DbaseFileHeader dbfHeader, int index)
	{
		char dataType = dbfHeader.getFieldType(index);
		String sqlDataType = "";
		if (dataType == 'C')
			sqlDataType = "VARCHAR(" + dbfHeader.getFieldLength(index)+ ")";
		else if (dataType == 'N' || dataType == 'F')
		{
			//if it has not 0 decimals return type as integer else Double Precision
			if(dbfHeader.getFieldDecimalCount(index) == 0)
				sqlDataType = "BIGINT";
			else
				sqlDataType = "DOUBLE PRECISION";
		}
		else if (dataType == 'D')
		{
			sqlDataType = "DATETIME";
		}
		else
		{
			throw new RuntimeException("Unknown DBF data type: "+dataType+" in column "+dbfHeader.getFieldName(index));
		}
		return sqlDataType;
	}
}
