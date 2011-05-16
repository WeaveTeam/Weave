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
import java.util.Iterator;
import java.util.List;

import weave.config.ISQLConfig;

/**
 * A CompareReport collects data about a subset and compares it to data 
 * about the entire dataset.  
 * @author Mary Beth
 *
 * example:
 * indicator     Entire dataset        mygeo 
 * indicator     entire dataset value  mygeo
 * 
 * we'll need to get a list of indicators
 * do totals 
 * start with obesity  
 * 1995          avg for all states    avg for my geo
 * 1996          avg for all states    avg for my geo
 * 1997          avg for all states    avg for my geo
 */
public class CompareReport extends ReportResult
{
	List <String> attributeNames = null; 
	List <String> attributeYears = null;
	
	public CompareReport(ISQLConfig config, String publishPath) 
	{
		super(config, publishPath);
	}
	
	/** createReport
	 *  Creates an html file on this server.  
	 *  @return success or failure + the report name
	 * @throws Exception 
	 */
	public String fillInReportContents(ReportDefinition reportDefinition)
		throws Exception
	{
		if ((reportDefinition.indicatorsA == null) || (reportDefinition.indicatorsA.size() == 0))
		{
			attributeNames = reportDefinition.indicatorsB;
			attributeYears = reportDefinition.yearsB;
		}
		else
		{
			attributeNames = reportDefinition.indicatorsA;
			attributeYears = reportDefinition.yearsA;
		}
		String result = "";
		writeCompareReportHeader(reportDefinition.reportDataTable);
		//loop through indicators
		AttributeColumnData columnData = new AttributeColumnData(config);
		Iterator<String> indicatorNameIterator = this.attributeNames.iterator();
		int iYear = 0;
		String year = "";
		writeLine("<table>");
		int numberOfDataPoints = 0;
		while (indicatorNameIterator.hasNext())
		{
			writeLine("<tr>");
			//write name of indicator
			String indicatorName = indicatorNameIterator.next();
			if ((attributeYears != null) && (attributeYears.size() > 0))
			{
				year = attributeYears.get(iYear++);				
			}
			writeLine(String.format("<td width = '229' align = 'left'>%s %s</td>", indicatorName, year));
			
			//write average for whole dataset 
			//get column
			columnData.getData(reportDefinition.reportDataTable, indicatorName, year);
			// calculate average
			String avg = getAverage(columnData.data);
			writeLine(String.format("<td width = '100' align = 'center'>%s</td>", avg));
				
			//write average for selected keys
			numberOfDataPoints += columnData.getData(reportDefinition.reportDataTable, indicatorName, year, _reportKeys);
			avg = getAverage(columnData.data);
			writeLine(String.format("<td width = '100' align = 'center'>%s</td>", avg));
			
			writeLine("</tr>");
		}
		writeLine("</table>");
		writeCompareReportFooter();
		if (numberOfDataPoints <= 0)
		{
			String errorMsg = "Key '" + _reportKeys.get(0) + "' not found in " + reportDefinition.reportDataTable;
			throw new RemoteException(errorMsg);
		}
			
		result = WeaveReport.REPORT_SUCCESS + " " + _reportName;
		return result; 
	}
	
	private void writeCompareReportHeader(String dataTableName)
		throws IOException
	{
		if (templateAvailable())
			writeTemplateHeader();
		else
		{
			writeLine(String.format("<html><h1 align='center'>%s\n</h1>", dataTableName));
			writeLine("<table>");
			writeLine("<tr><td width = '229'>Indicators</td><td width = '100' align = 'center' >Dataset Average</td><td width = '100' align = 'center'>Selection Average</tr>");
			writeLine("</table>");
		}
		
	}

	private void writeCompareReportFooter()
	throws IOException
	{
		if (templateAvailable())
		{
			writeTemplateFooter();
		}
		else
		{
			writeStandardFooter();
			writeLine("</html>");
		}
		
	}
	
	
	
	

}
