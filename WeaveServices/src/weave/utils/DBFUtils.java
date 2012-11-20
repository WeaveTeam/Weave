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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.charset.Charset;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.geotools.data.shapefile.dbf.DbaseFileHeader;
import org.geotools.data.shapefile.dbf.DbaseFileReader;

 
/**
 * @author skolman
 * @author adufilie
 */
/**
 * @author Andy
 *
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
	 * Tests a combined column for uniqueness across several files
	 * @param dbfFile
	 * @param columnNames
	 * @return 
	 * @throws IOException
	 */
	public static boolean isColumnUnique(File[] dbfFile, String[] columnNames) throws IOException
	{
		Set<Object> set = new HashSet<Object>();
		for (File file : dbfFile)
		{
			Object[][] rows = getDBFData(file, columnNames);
			for (int i = 0; i < rows.length; i++)
			{
				// concatenate all values into a string
				StringBuilder sb = new StringBuilder();
				for (Object str : rows[i])
					sb.append(str);
				String value = sb.toString();
				
				// check if we have seen this value before
				if (set.contains(value))
					return false;
				
				// remember this value
				set.add(value);
			}
		}
		return true;
	}
	
	/**
	 * @param dbfFile A DBF file
	 * @param fieldNames A list of field names to retrieve, or null for all columns
	 * @return A list of attribute names in the DBF file
	 */
	public static Object[][] getDBFData(File dbfFile, String[] fieldNames) throws IOException
	{
		List<String> allFields = getAttributeNames(dbfFile);
		FileInputStream fis = new FileInputStream(dbfFile);
		DbaseFileReader dbfReader = new DbaseFileReader(fis.getChannel(), false, Charset.forName("ISO-8859-1"));
		
		//contains the header columns
		DbaseFileHeader dbfHeader = dbfReader.getHeader();
		
		List<Object[]> rowsList = new Vector<Object[]>();
		

		while(dbfReader.hasNext())
		{
			Object[] row;
			if (fieldNames != null)
			{
				row = new Object[fieldNames.length];
				for (int i = 0; i < fieldNames.length; i++)
					row[i] = dbfReader.readField(allFields.indexOf(fieldNames[i]));
			}
			else
			{
				row = dbfReader.readEntry();
			}
			rowsList.add(row);
		}
		
		
		
		int numOfCol = dbfHeader.getNumFields();
		
		Object[][] dataRows = new Object[rowsList.size()][numOfCol];
		
		for(int i=0; i < rowsList.size();i++)
		{
			dataRows[i] = rowsList.get(i);
			
		}
		
		return dataRows;
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
		
		FileInputStream[] inputStreams = new FileInputStream[dbfFiles.length];
		DbaseFileHeader[] headers = new DbaseFileHeader[dbfFiles.length];
		DbaseFileReader[] readers = new DbaseFileReader[dbfFiles.length];
		
		// open each file, read each header, get the complete list of field names and types
		for (int i = 0; i < dbfFiles.length; i++)
		{
			inputStreams[i] = new FileInputStream(dbfFiles[i]);
			readers[i] = new DbaseFileReader(inputStreams[i].getChannel(), false, Charset.forName("ISO-8859-1"));
			headers[i] = readers[i].getHeader();
			
			int numFields = headers[i].getNumFields();
			// keep track of the full set of field names
			for (int col = 0; col < numFields; col++)
			{
				String newFieldName = headers[i].getFieldName(col);
				if (ListUtils.findString(newFieldName, fieldNames) < 0)
				{
					fieldNames.add(newFieldName);
					fieldTypes.add(getSQLDataType(conn, headers[i], col));
				}
			}
		}
		
		// begin SQL code
		try
		{
			conn.setAutoCommit(false);
			
			// create the table
			if (overwriteTables)
				SQLUtils.dropTableIfExists(conn, sqlSchema, sqlTable);
			fieldNames.add(0, "the_geom_id");
			fieldTypes.add(0, SQLUtils.getSerialPrimaryKeyTypeString(conn));
			SQLUtils.createTable(conn, sqlSchema, sqlTable, fieldNames, fieldTypes);
			
			// import data from each file
			for (int f = 0; f < dbfFiles.length; f++)
			{
				int numFields = headers[f].getNumFields();
				int numRecords = headers[f].getNumRecords();
				// insert records from this file
				for (int r = 0; r < numRecords; r++)
				{
					Map<String,Object> record = new HashMap<String, Object>();
					Object[] entry = readers[f].readEntry();
					for (int c = 0; c < numFields; c++)
					{
						if (ListUtils.findIgnoreCase(entry[c].toString(), nullValues) < 0)
							record.put(headers[f].getFieldName(c), entry[c]);
					}
					
					// insert the record in the table
					try
					{
						SQLUtils.insertRow(conn, sqlSchema, sqlTable, record);
					}
					catch (SQLException e)
					{
						System.out.println(String.format("Insert failed on row %s of %s: %s", r, dbfFiles[f].getName(), record));
						throw e;
					}
				}
				// close the file
				readers[f].close();
				inputStreams[f].close();
				// clean up pointers
				readers[f] = null;
				inputStreams[f] = null;
				headers[f] = null;
			}
		}
		finally
		{
			conn.setAutoCommit(true);
		}
	}
	
	//returns a string format of the SQL Datatype of the column using the getFieldType function from DBaseFileHeader
	private static String getSQLDataType(Connection conn, DbaseFileHeader dbfHeader, int index)
	{
		char dataType = dbfHeader.getFieldType(index);
		String sqlDataType = "";
		if (dataType == 'C')
			sqlDataType = SQLUtils.getVarcharTypeString(conn, dbfHeader.getFieldLength(index));
		else if (dataType == 'N' || dataType == 'F')
		{
			//if it has not 0 decimals return type as integer else Double Precision
			if(dbfHeader.getFieldDecimalCount(index) == 0)
				sqlDataType = SQLUtils.getBigIntTypeString(conn);
			else
				sqlDataType = SQLUtils.getDoubleTypeString(conn);
		}
		else if (dataType == 'D')
		{
			sqlDataType = SQLUtils.getDateTimeTypeString(conn);
		}
		else
		{
			throw new RuntimeException("Unknown DBF data type: "+dataType+" in column "+dbfHeader.getFieldName(index));
		}
		return sqlDataType;
	}
}
