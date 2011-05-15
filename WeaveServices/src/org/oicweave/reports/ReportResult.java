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
package org.oicweave.reports;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.FilenameFilter;
import java.io.IOException;
import java.rmi.RemoteException;
import java.text.DateFormat;
import java.text.DecimalFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;

import org.oicweave.reports.ReportFactory.ReportType;
import org.oicweave.servlets.DataService;
import org.oicweave.config.ISQLConfig;

public abstract class ReportResult 
{
	//the list of keys that will be in the report
    public List<String> _reportKeys = null;
    public String _reportName = "";
    public ReportType _reportType = null;
    private ReportDefinition _reportDefinition = null;
    
    //the path 
    private String _publishPath = null;

	protected ISQLConfig config;
	protected ReportResult(ISQLConfig conf, String publishPath)
	{
		config = conf;
		_publishPath = publishPath;
	}
	

	public String createReport(DataService dataSource, ReportDefinition reportDefinition, List<String> keys)
		throws Exception
	{
		_publishPath = reportDefinition._path;
		_reportDefinition = reportDefinition; 
		String result;
		try {
			_reportKeys = keys;  
			createReportFile();
			result = fillInReportContents(reportDefinition);
		}
//		catch (Exception e)
//		{
//			throw new RemoteException(WeaveReport.REPORT_FAIL, e);
//		}
		finally
		{
			try
			{
				_reportKeys.clear(); //we only save the list while we are creating the report
				if (_writer != null) _writer.close();
			}
			catch (Exception e)
			{ }
		}
		return result;
	}

	/** 
	 * createReport
	 * Creates an html file on this server.  
	 * This must be overridden by the specific type of report
	 * @return success or failure + the report name
	 * @throws Exception 
	 */
	public String fillInReportContents(ReportDefinition reportDefinition) throws RemoteException, Exception
	{
		return WeaveReport.REPORT_FAIL + " fillInReportContest must be overloaded by the type of report";
	}
	
	public String fillInReportContents()
	throws RemoteException, Exception
	{
		return WeaveReport.REPORT_FAIL + " fillInReportContest must be overloaded by the type of report";
	}

	private FileReader template = null;
	protected FileReader getTemplate(String reportType) throws FileNotFoundException 
	{
		if (template == null)
		{
			//file
			File templateFile = new File(_publishPath, _reportDefinition._reportDefinitionFileName);
			if (templateFile.exists())
			{
				template = new FileReader(templateFile);
				return template;
			}
			else
				return null;
		}
		return template;		
	}
	
	//creates the file itself, but it gets filled in somewhere else
	public void createReportFile() throws IOException
	{
		File dir = new File(_publishPath, WeaveReport.REPORTS_DIRECTORY);
		dir.mkdirs();
		deleteOldReports(dir);
		
		File file = File.createTempFile("report", ".html", dir);
		_reportName = file.getName();
		if (! file.exists())
			throw new IOException(file.getAbsolutePath() + " does not exist");
		FileWriter fwriter = new FileWriter(file);
		_writer = new BufferedWriter(fwriter);			
	}

	// for each column name get a column of data and add it to the columns array
	public AttributeColumnData[] getColumnData(String dataTableName, List<String>columnNames, List<String>years) 
	throws RemoteException
	{
		AttributeColumnData[] columns = new AttributeColumnData[columnNames.size()];
		int i = 0;
		int numberOfDataPoints = 0;
		String year = "";
		for (ListIterator<String> iter = columnNames.listIterator(); iter.hasNext();)
		{
			AttributeColumnData column = new AttributeColumnData(config);
			if ((years != null) && (years.size() > 0))
				year = years.get(i);
			numberOfDataPoints += column.getData(dataTableName, iter.next(), year, _reportKeys);  //get the whole column
			columns[i++] = column;
			//columns[i++] = getColumnData(dataTableName, iter.next());
		}
		if (numberOfDataPoints <= 0)
		{
			String errorMsg = "Key '" + _reportKeys.get(0) + "' not found in " + dataTableName;
			throw new RemoteException(errorMsg);
		}
		return columns;
	}
	
	//clean up - delete old reports
	//  if we don't do this they will keep growing infinitely
	//using a heuristic - deleting reports that were not created within the last 24 hours
	public void deleteOldReports(File dir)
	{
		FilenameFilter filter = new FilenameFilter() 
		{
			public boolean accept(File dir, String name)
			{
				return (name.startsWith("report") && name.endsWith(".html"));
			}
		};
		File[] reportFiles = dir.listFiles(filter);
		if (reportFiles == null)
			return; 
		long timeNow = Calendar.getInstance().getTimeInMillis();
		long millisInAnHour = 3600000;  //number of milliseconds in an hour
		long timeAnHourAgo = timeNow - millisInAnHour;
		for (int i = 0; i < reportFiles.length; i++)
		{
			File file = reportFiles[i];
			long fileTimeStamp = file.lastModified();
			if (fileTimeStamp < timeAnHourAgo)
				file.delete();
		}
	}
	
	protected BufferedReader _templateReader = null;
	protected BufferedWriter _writer = null;
	private FileReader _reader = null;
	protected String _line = null;
	//get an html template file for this report type.  
	protected String _templateFilePath = "";
	protected boolean templateAvailable()
	{
		return templateAvailable(_reportDefinition._reportDefinitionFileName);
	}
	
	private File getTemplateFile(String templateName)
	{
		//check docroot for the template file
		_templateFilePath = _publishPath + "/" + WeaveReport.REPORTS_DIRECTORY + "/" + templateName;
		File templateFile = new File(_templateFilePath);
		return templateFile;
		
	}
	
	protected boolean templateAvailable(String templateName)
	{
		//if it's already been opened, return true
		if (_templateReader != null)
			return true;
		
		//get the file that contains the template
		File templateFile = getTemplateFile(templateName);
		
		
		//we require that it contain the reportdata tags,
		//  that way we ensure that it is a template file
		if ((templateFile.exists()) && (containsReportTags(templateFile)))
		{
			try {
				_reader = new FileReader(templateFile);
				_templateReader = new BufferedReader(_reader);
			} catch (FileNotFoundException e) {
				//do nothing
			}			
		}

		return (_templateReader != null);			
	}
	
	private boolean containsReportTags(File templateFile)
	{
		boolean validFile = false;
		if (! templateFile.exists())
			return false;

		
		BufferedReader templateReader = null;
		FileReader reader = null;
		try 
		{
			reader = new FileReader(templateFile);
			//we require that it contain the reportdata tags,
			//  that way we ensure that it is a template file
			templateReader = new BufferedReader(reader);
			int iStartTag = -1;
			String line = null;
			while ((iStartTag == -1) && ((line = templateReader.readLine()) != null))
			{
				iStartTag = line.indexOf(WeaveReport.REPORT_DATA_START_TAG);
			}
			//we found the tag that validates this as a template file
			validFile = (iStartTag != -1);
		} 
		catch (FileNotFoundException e) { } 
		catch (IOException e) { }
		finally
		{
			try 
			{ 
				if (templateReader != null)
					templateReader.close(); 
				if (reader != null)
					reader.close();						
			}
			catch (IOException e) 
			{
				//do nothing, we just had to try to close it in case it was left open
			}
		}
		return validFile;
	}
		
	
	protected void writeTemplateHeader() throws IOException
	{
		if (! templateAvailable())
			return;
		
		
		int iStartTag = -1;
		while ((iStartTag == -1) && (_line = _templateReader.readLine()) != null)
		{
			iStartTag = _line.indexOf(WeaveReport.REPORT_DATA_START_TAG);
			if (iStartTag == -1)
				writeLine(_line);
		}
		//if we found the start tag, write the line up to the tag
		if (iStartTag != -1)
		{
			String upToReportTag = _line.substring(0, iStartTag);
			writeLine(upToReportTag);			
		}
		else
		{
			throw new IOException(WeaveReport.REPORT_DATA_START_TAG + " not found in template file "
					+ _templateFilePath);
		}
	}
	
	protected void writeTemplateFooter() throws IOException
	{
		if (_templateReader == null)
			return;
		if (_line != null)
		{
			//get past the </body> tag
			int iEndTag = _line.indexOf(WeaveReport.REPORT_DATA_END_TAG);
			while ((iEndTag == -1) && (_line = _templateReader.readLine()) != null)
			{ 
				iEndTag = _line.indexOf(WeaveReport.REPORT_DATA_END_TAG);
			}
			//start writing
			_writer.write(_line.substring(iEndTag));
			//write all the rest of the lines
			iEndTag = _line.indexOf("</html>");
			if (iEndTag == -1)
				iEndTag = _line.indexOf("</HTML>");
			while((iEndTag == -1) && (_line = _templateReader.readLine()) != null)
			{
				iEndTag = _line.indexOf("</html>");
				if ((iEndTag == -1) && ((iEndTag = _line.indexOf("</HTML>")) == -1))
					writeLine(_line);
				else
				{
					writeStandardFooter();
				}
			}
			
			//write end tag
			writeLine(_line);
		}
		_templateReader.close();
	}
	
	protected void writeStandardFooter() throws IOException
	{
		Date d = new Date();
		String date = (DateFormat.getDateTimeInstance(DateFormat.LONG, DateFormat.LONG).format(d));
		_writer.write("<table cellSpacing=0 cellPadding=0 width=100% align=left border=0 >"
			+ "<tr> <td align=right class=note color=blue><u>Report generated by" 
			+				" the Open Indicators Consortium Weave software.<br>" + date + "<br></td> </tr></table>");
		_writer.newLine();			
		//CSS Styles
		_writer.write("<style type='text/css'>");
		_writer.newLine();
		_writer.write(".note { COLOR: #555555; FONT-FAMILY:  arial; FONT-SIZE: 7pt; FONT-WEIGHT: normal }");
		_writer.newLine();
		_writer.write(".c2ktitle { BACKGROUND-COLOR: #dddddd; COLOR: #555555; FONT-FAMILY:  arial; FONT-SIZE: 8pt; FONT-WEIGHT: bold }");
		_writer.newLine();
		_writer.write(".title {COLOR: darkblue; FONT-FAMILY:  arial; FONT-SIZE: 11pt; FONT-WEIGHT: bold}");
		_writer.newLine();
		_writer.write(".subtitle { BACKGROUND-COLOR: #d7d1ff; COLOR: darkblue; FONT-FAMILY:  arial; FONT-SIZE: 9pt; FONT-WEIGHT: bold }");
		_writer.newLine();
		_writer.write("</style>");
		_writer.newLine();
	}

	//a little helper function 
	protected void writeLine(String line) throws IOException
	{
		_writer.write(line);
		_writer.newLine();
	}

	
	//this is a wrapper around AttributeColumnDataWithKeys
	//  it decodes the data for use in the report 
	//  @TODO - get the data as a cached rowset - not after it's decoded
	
	public static String getAverage(List<String> data)
	{
		//get column sum and count
		Iterator<String> iter = data.iterator();
		String strValue = null;
		float  fltValue = 0; 
		float sum = 0;
		int   count = 0;
		while (iter.hasNext())
		{
			strValue = iter.next();
			try {
				fltValue = Float.valueOf(strValue);
				sum += fltValue;
				count++;
			} catch (NumberFormatException e) {
				//do nothing if it is not a valid number
			}
		}
		
		//average
		float fltAvg = sum / count;

		//make sure it's only 2 decimal places
		DecimalFormat formatter = new DecimalFormat("0.##");
		strValue = formatter.format(fltAvg);
		//strValue = String.valueOf(fltAvg);
		
		return strValue; 		
	}

}
