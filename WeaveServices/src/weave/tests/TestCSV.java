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

import weave.utils.CSVParser;

public class TestCSV
{

	/**
	 * @param args
	 */
	public static void main(String[] args) throws Exception
	{
		File file = new File("src/weave/tests/test.csv");
		System.out.println(file.getAbsolutePath());
		
		System.out.println("parseCSV(csvData)");
		String[][] parsedRows = CSVParser.defaultParser.parseCSV(file, true);
		for (int i = 0; i < parsedRows.length; i++)
		{
			for (int j = 0; j < parsedRows[i].length; j++)
				System.out.println(String.format("rows[%s][%s] = %s", i, j, parsedRows[i][j]));
		}
		System.out.println("Compare these results with Microsoft Excel\n");
		
		System.out.println("parseCSV(csvData, false), parseCSVToken, createCSVToken, parseCSVToken");
		String[][] rows = CSVParser.defaultParser.parseCSV(file, true); // assuming this isn't sql server
		for (int i = 0; i < rows.length; i++)
		{
			for (int j = 0; j < rows[i].length; j++)
			{
				String token = rows[i][j];
				String parsed = CSVParser.defaultParser.parseCSVToken(token);
				String created = CSVParser.defaultParser.createCSVToken(parsed, false);
				String parsedAgain = CSVParser.defaultParser.parseCSVToken(created);
				System.out.println(String.format("rows[%s][%s] = %s = %s = %s = %s", i, j, token, parsed, created, parsedAgain));
				if (!parsed.equals(parsedRows[i][j]))
					throw new Error(String.format("Parsed tokens do not match: %s != %s", parsedRows[i][j], parsed));
				if (!parsed.equals(parsedAgain))
					throw new Error(String.format("Parsed tokens do not match: %s != %s", parsed, parsedAgain));
			}
		}
	}
}
