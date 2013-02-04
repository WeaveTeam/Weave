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
package weave.reports;

import java.io.IOException;
import java.rmi.RemoteException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

import weave.config.ISQLConfig;

/**
 * A Category report has a row for each key in the list of keys 
 * the data is categorized
 * e.g. 
 * 	Release One
 *         Website
 *                  bug on website          more info about bug
 *                  another bug on website  more info about the other bug
 *         Software
 *                  bug in software
 *  Release Two
 *         Website
 *                  bug on website         more info about bug
 *                  another one
 * @author Mary Beth
 */
public class CategoryReport extends ReportResult
{
	List<String> categoryAttributeNames = null;
	List<String> showAttributeNames = null;
	List<String> categoryAttributeYears = null;
	List<String> showAttributeYears = null;

	public CategoryReport(ISQLConfig config, String publishPath)
	{
		super(config, publishPath);
	}

	/** createReport
	 *  Creates an html file on this server.  
	 *  Overrides AbstractReport.createReport
	 *  @return success or failure + the report name
	 * @throws IOException 
	 */
	public String fillInReportContents(ReportDefinition reportDefinition)
		throws IOException
	{
		categoryAttributeNames = reportDefinition.indicatorsA;
		showAttributeNames = reportDefinition.indicatorsB;
		categoryAttributeYears = reportDefinition.yearsA;
		showAttributeYears = reportDefinition.yearsB;
		ArrayList<CategoryReportRow> reportRows = getReportData(reportDefinition.reportDataTable);
		String result = writeReportData(reportDefinition.reportDataTable, reportRows);
		return result;
	}
	
	private ArrayList<CategoryReportRow> getReportData(String dataTableName)
		throws RemoteException
	{
		ArrayList<CategoryReportRow> reportRows = new ArrayList<CategoryReportRow>();
		//get category data columns
		AttributeColumnData[] categoryColumnData = getColumnData(dataTableName, categoryAttributeNames, categoryAttributeYears);
		
		//get attribute data columns
		AttributeColumnData[] attributeColumnData = getColumnData(dataTableName, showAttributeNames, showAttributeYears);
		
		//from the columns, get the data only for the subset of keys that will go into the report
		Iterator<String> reportKeysIter = _reportKeys.iterator();
		String dataValueForKey = null; 
		while (reportKeysIter.hasNext())
		{			
			String currKey = (String)reportKeysIter.next();
			CategoryReportRow reportData = new CategoryReportRow();
						
			//categories			
			for(AttributeColumnData attrData : categoryColumnData)
			{
				dataValueForKey = attrData.getDataForKey(currKey);
				if (dataValueForKey == null)
					dataValueForKey = "";
				reportData.catValues.add(dataValueForKey);
			}
			
			//data within the categories
			for (AttributeColumnData attrData : attributeColumnData)
			{
				dataValueForKey = attrData.getDataForKey(currKey);
				reportData.attrValues.add(dataValueForKey);						
			}
						
			//add it to the array and move to next key in the parameter list
			reportRows.add(reportData);
		}
		//sort
		Collections.sort(reportRows);		
		return reportRows;
	}

	private void writeCategoryReportHeader(String dataTableName)
	throws IOException
	{
		if (templateAvailable())
			writeTemplateHeader();
		else
			writeLine(String.format("<html><h1 align='center'>%s\n</h1>", dataTableName));
	}

	private String writeReportData(String dataTableName, ArrayList<CategoryReportRow> reportLines) throws IOException 
	{
		//header
		writeCategoryReportHeader(dataTableName);

		//loop through category values
		for (int iLine = 0; iLine < reportLines.size();)
		{
			CategoryReportRow row = reportLines.get(iLine);
			String currentCatValue = row.catValues.get(0);
			writeLine(String.format("<h2>%s</h2>", currentCatValue));
			//writer.write("<tr class=subtitle><td align=left width=300>" + currentCatValue + "</td><td></td></tr>");
			//loop through subcategory values
			while ((iLine < reportLines.size()) && (currentCatValue.equals(row.catValues.get(0)))) //r.release)))
			{
				String currentSubCatValue = row.catValues.get(1); 
				writeLine(String.format("<h3>%s</h3>", currentSubCatValue));
				//writer.write(String.format("<tr class=subtitle><td>%s</td><td></td></tr>", currentSubCatValue));
				//loop through lines in this subcategory
				writeLine("<table>");
				while ((iLine < reportLines.size()) && 
						((currentSubCatValue == null) && (row.catValues.get(1) == null) || 
						(currentSubCatValue.equals(row.catValues.get(1)))))
				{
					row.writeLine(_writer);
					if (++iLine < reportLines.size())
						row = reportLines.get(iLine);
				}					
				writeLine("</table>");
			}
		}
		
		// footer
		writeCategoryReportFooter();
		return(WeaveReport.REPORT_SUCCESS + " " + _reportName);
	}

	private void writeCategoryReportFooter()
	throws IOException
	{
		if (templateAvailable())
			writeTemplateFooter();
		else
		{
			writeStandardFooter();
			writeLine("</html>");
		}	
	}
	
}
