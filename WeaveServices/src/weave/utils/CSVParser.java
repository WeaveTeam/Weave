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

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.StringWriter;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

/**
 * This is an all-static class containing functions to parse and generate valid CSV-encoded tables of Strings.
 * 
 * @author adufilie
 */	
public class CSVParser
{
	public static final CSVParser defaultParser = new CSVParser();
	
	/**
	 * This is the default constructor which creates a CSVParser having a delimiter of ',' and a quote of '"'.
	 */
	public CSVParser()
	{
	}

	/**
	 * This creates a CSVParser having a custom delimiter.
	 */
	public CSVParser(char delimiter)
	{
		this.delimiter = delimiter;
	}
	
	/**
	 * This creates a CSVParser having a custom delimiter and quote symbol.
	 */
	public CSVParser(char delimiter, char quote)
	{
		this.quote = quote;
		this.delimiter = delimiter;
	}
	
	private char quote = '"'; // this gets set in the constructor and should not change
	private char delimiter = ','; // this gets set in the constructor and should not change

	public static final char CR = '\r';
	public static final char LF = '\n';
	
	/**
	 * This function will decode a CSV token, removing quotes and un-escaping quotes where applicable.
	 * If the String begins with a " then the characters up until the matching " will be parsed, replacing "" with ".
	 * For example, the String "ab,c""xyz" becomes ab,c"xyz
	 * @param token The CSV-encoded token to parse.
	 * @return The result of parsing the token.
	 */
	public String parseCSVToken(String token)
	{
		String parsedToken = "";
		
		int tokenLength = token.length();
		
		if (token.charAt(0) == quote)
		{
			boolean escaped = true;
			for (int i = 1; i < tokenLength; i++)
			{
				char thisChar = token.charAt(i);
				char nextChar = (i < tokenLength - 1) ? token.charAt(i + 1) : 0;
				
				if (thisChar == quote && nextChar == quote) //append escaped quote
				{
					i += 1;
					parsedToken += quote;
				}
				else if (thisChar == quote && escaped)
				{
					escaped = false;
				}
				else
				{
					parsedToken += thisChar;
				}
			}
		}
		else
		{
			parsedToken = token;
		}
		return parsedToken;
	}
	
	/**
	 * This function encodes a String as a CSV token, adding quotes around it and replacing " with "" if necessary.
	 * For example, the String ab,c"xyz becomes "ab,c""xyz"
	 * @param str The String to encode as a CSV token.
	 * @return The String encoded as a CSV token.
	 */
	public String createCSVToken(String str, boolean quoteEmptyStrings)
	{
		if (str == null)
			str = "";
		
		// determine if quotes are necessary
		if ( (str.length() > 0 || !quoteEmptyStrings)
			&& str.indexOf(quote) < 0
			&& str.indexOf(delimiter) < 0
			&& str.indexOf(LF) < 0
			&& str.indexOf(CR) < 0
			&& str.equals(str.trim()) )
		{
			return str;
		}

		StringBuilder token = new StringBuilder();
		for (int i = 0; i < str.length(); i++)
		{
			char currentChar = str.charAt(i);
			token.append(currentChar);
			// escape quotes
			if (currentChar == quote)
				token.append(quote);
		}
		return String.format("%s%s%s", quote, token, quote);
	}
	
	/**
	 * @private
	 * Helper function used by parseCSV.
	 */
	private StringBuilder newToken(Vector<Vector<StringBuilder>> rows, boolean newRow)
	{
		if (newRow)
			rows.add(new Vector<StringBuilder>());
		StringBuilder token = new StringBuilder();
		rows.lastElement().add(token);
		return token;
	}
	
	/**
	 * This function parses a String as a CSV-encoded table.
	 * @param csvData The CSV string to parse.
	 * @param parseTokens If this is true, tokens surrounded in quotes will be unquoted and escaped characters will be unescaped.
	 * @return The result of parsing the CSV string.
	 */
	public String[][] parseCSV(String csvData, boolean parseTokens)
	{
		try {
			return parseCSV(new ByteArrayInputStream(csvData.getBytes()), parseTokens);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			return null;
		}
	}
	/**
	 * This function parses a String as a CSV-encoded table.
	 * @param csvData The CSV file to parse.
	 * @param parseTokens If this is true, tokens surrounded in quotes will be unquoted and escaped characters will be unescaped.
	 * @return The result of parsing the CSV string.
	 */
	public String[][] parseCSV(File csvFile, boolean parseTokens) throws IOException
	{
		return parseCSV(new FileInputStream(csvFile), parseTokens);
	}
	/**
	 * This function parses a String as a CSV-encoded table.
	 * @param csvData The CSV input to parse.
	 * @param parseTokens If this is true, tokens surrounded in quotes will be unquoted and escaped characters will be unescaped.
	 * @return The result of parsing the CSV string.
	 */
	public String[][] parseCSV(InputStream csvInput, boolean parseTokens) throws IOException
	{
		InputStreamReader csvReader = new InputStreamReader(csvInput, "ISO-8859-1");
		
		Vector<Vector<StringBuilder>> rows = new Vector<Vector<StringBuilder>>();

		// special case -- if csv is empty, return an empty array (a set of zero rows)
		if (csvInput.available() == 0)
			return new String[0][];
		
		StringBuilder token = newToken(rows, true); // new row

		boolean escaped = false;
		
		int next = csvReader.read();
		boolean skipNext = false;
		
		while (next != -1)
		{
			char chr = (char) next;
			next = csvReader.read();
			
			if (skipNext)
			{
				skipNext = false;
				continue;
			}
			
			if (escaped)
			{
				if (chr == quote)
				{
					// append quote if not parsing tokens
					if (!parseTokens)
						token.append(quote);
					if (next == quote) // escaped quote
					{
						// always append second quote
						token.append(quote);
						// skip second quote mark
						skipNext = true;
					}
					else // end of escaped text
					{
						escaped = false;
					}
				}
				else
				{
					token.append(chr);
				}
			}
			else
			{
				if (chr == delimiter)
				{
					// start new token on same row
					token = newToken(rows, false);
				}
				else if (chr == quote && token.length() == 0)
				{
					// beginning of escaped token
					escaped = true;
					if (!parseTokens)
						token.append(chr);
				}
				else if (chr == LF)
				{
					// start new token on new row
					token = newToken(rows, true);
				}
				else if (chr == CR)
				{
					// handle CRLF
					if (next == LF)
						skipNext = true; // skip line feed
					// start new token on new row
					token = newToken(rows, true);
				}
				else //append single character to current token
					token.append(chr);
			}
		}
		
		// if there is more than one row and last row is empty,
		// remove last row assuming it is there because of a newline at the end of the file.
		while (rows.size() > 1)
		{
			Vector<StringBuilder> lastRow = rows.lastElement();
			if (lastRow.size() == 1 && lastRow.lastElement().length() == 0)
				rows.remove(rows.size() - 1); // remove last row
			else
				break;
		}
		
		// find the maximum number of columns in a row
		int columnCount = 0;
		for (Vector<StringBuilder> row : rows)
			columnCount = Math.max(columnCount, row.size());
		
		// create a 2D String array
		String[][] result = new String[rows.size()][];
		for (int i = 0, j; i < rows.size(); i++)
		{
			Vector<StringBuilder> rowVector = rows.get(i);
			rows.set(i, null); // free the memory
			String[] rowArray = new String[columnCount];
			// the row may not have all the columns
			for (j = 0; j < rowVector.size(); j++)
			{
				rowArray[j] = rowVector.get(j).toString();
				rowVector.set(j, null); // free the memory
			}
			// fill remaining columns with empty Strings
			for (; j < columnCount; j++)
				rowArray[j] = "";
			result[i] = rowArray;
		}
		
		return result;
	}
	
	/**
	 * This function encodes an Array of objects into a CSV row.
	 * @param rows An array of row values.  If the row values are not Strings, toString() will be called on each value.
	 * @return The row encoded as a CSV String.
	 */
	public String createCSVRow(Object[] row, boolean quoteEmptyStrings) throws IOException
	{
		return createCSV(new Object[][]{ row }, quoteEmptyStrings, false);
	}
	
	/**
	 * This function converts a table of Strings (or Objects) and encodes them as a single CSV String.
	 * @param rows An array of rows.  If the row values are not Strings, toString() will be called on each value.
	 * @return The rows encoded as a CSV String.
	 */
	public String createCSV(Object[][] rows, boolean quoteEmptyStrings, boolean endingLineFeed) throws IOException
	{
		StringWriter out = new StringWriter();
		createCSV(rows, quoteEmptyStrings, out, endingLineFeed);
		return out.toString();
	}
	
	/**
	 * This function converts a table of Strings (or Objects) and encodes them as a single CSV String.
	 * @param rows An array of rows.  If the row values are not Strings, toString() will be called on each value.
	 * @param output Where the result will be directed.
	 * @param endingLineFeed Set to true to end the output with a line feed.
	 * @throws IOException 
	 */
	public void createCSV(Object[][] rows, boolean quoteEmptyStrings, Appendable output, boolean endingLineFeed) throws IOException
	{
		String nullToken = quoteEmptyStrings ? "" : null;
		for (int iRow = 0; iRow < rows.length; iRow++)
		{
			if (iRow > 0)
				output.append(LF);
			
			Object[] row = rows[iRow];
			for (int iCol = 0; iCol < row.length; iCol++)
			{
				Object value = row[iCol];
				String token = value == null ? nullToken : createCSVToken(value.toString(), quoteEmptyStrings);
				if (iCol > 0)
					output.append(delimiter);
				output.append(token);
			}
		}
		if (endingLineFeed)
			output.append(LF);
	}
	
	/**
	 * This function converts an Array of Arrays to an Array of Objects compatible with DataGrid.
	 * @param rows An Array of Arrays, the first being a header line containing property names
	 * @return An Array of Objects containing String properties using the names in the header line.
	 */
	public Map<String,String>[] convertRowsToRecords(String[][] rows)
	{
		@SuppressWarnings("unchecked")
		Map<String,String>[] records = new Map[rows.length];
		if (rows.length == 0)
			return records;
		
		String[] header = rows[0]; // these will be the keys in the record Map objects
		for (int i = 1; i < rows.length; i++)
		{
			String[] row = rows[i];
			Map<String,String> record = new HashMap<String,String>();
			for (int j = 0; j < header.length; j++)
				record.put(header[j], (j < row.length) ? row[j] : ""); // fill missing column values with empty strings
			records[i] = record;
		}
		return records;
	}
	
	/**
	 * This function returns a comprehensive list of all the field names defined by a list of record objects.
	 * @param records An Array of record objects.
	 * @return A comprehensive list of all the field names defined by the given record objects.
	 */
	public String[] getRecordFieldNames(Map<String,String>[] records)
	{
		return getRecordFieldNames(records, true);
	}
	/**
	 * This function returns a comprehensive list of all the field names defined by a list of record objects.
	 * @param records An Array of record objects.
	 * @param includeNullFields If this is true, fields that have null values will be included.
	 * @return A comprehensive list of all the field names defined by the given record objects.
	 */
	public String[] getRecordFieldNames(Map<String,String>[] records, boolean includeNullFields)
	{
		Map<String,Boolean> hashmap = new HashMap<String,Boolean>();
		for (Map<String,String> record : records)
			for (String field : record.keySet())
				if (includeNullFields || record.get(field) != null)
					hashmap.put(field, true);
		return (String[])hashmap.keySet().toArray();
	}
	
	/**
	 * This function converts an Array of Map objects to an Array of Arrays compatible with other functions in this class.
	 * @param records An Array of Objects containing String properties.
	 * @return An Array of Arrays, the first being a header line containing all the property names.
	 */
	public String[][] convertRecordsToRows(Map<String,String>[] records)
	{
		return convertRecordsToRows(records, null);
	}
	/**
	 * This function converts an Array of Map objects to an Array of Arrays compatible with other functions in this class.
	 * @param records An Array of Objects containing String properties.
	 * @param columnOrder An optional list of column names to use in order.
	 * @return An Array of Arrays, the first being a header line containing all the property names.
	 */
	public String[][] convertRecordsToRows(Map<String,String>[] records, String[] columnOrder)
	{
		return convertRecordsToRows(records, columnOrder, true);
	}
	/**
	 * This function converts an Array of Map objects to an Array of Arrays compatible with other functions in this class.
	 * @param records An Array of Objects containing String properties.
	 * @param columnOrder An optional list of column names to use in order.
	 * @param allowBlankColumns If this is set to true, then the function will include all columns even if they are blank.
	 * @return An Array of Arrays, the first being a header line containing all the property names.
	 */
	public String[][] convertRecordsToRows(Map<String,String>[] records, String[] columnOrder, boolean allowBlankColumns)
	{
		String[][] rows = new String[records.length + 1][]; // make room for the header
		
		String[] header = columnOrder;
		if (header == null)
		{
			header = getRecordFieldNames(records, allowBlankColumns);
			Arrays.sort(header);
		}
		
		rows[0] = header;
		
		for (int i = 0; i < records.length; i++)
		{
			Map<String,String> record = records[i];
			String[] row = new String[header.length];
			for (int j = 0; j < header.length; j++)
				row[j] = record.get(header[j]);
			rows[i + 1] = row;
		}
		return rows;
	}
}
