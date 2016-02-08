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
