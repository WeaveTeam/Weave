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

import java.util.List;

import weave.config.ISQLConfig;
import weave.servlets.DataService;

/**
 * WeaveReport creates a temporary html file on the server that the client
 * can then access via a url in the web browser
 * A WeaveReport is comprised of two things
 *    the report definition - created by the admin and stored in a file on the server and 
 *    the report result - created here at runtime and published on the server
 * @author Mary Beth Smrtic
 */
public class WeaveReport 
{
    public static final String REPORT_SUCCESS = "success";
    public static final String REPORT_FAIL = "fail";
    public static final String REPORTS_DIRECTORY = "WeaveReports";
    protected static final String REPORT_DATA_START_TAG = "<weavedata>";
    protected static final String REPORT_DATA_END_TAG = "</weavedata>";
	
	public WeaveReport(String publishPath)
	{
		_publishPath = publishPath;
	}

    private String _publishPath = null;  

    public String createReport(ISQLConfig config, DataService dataSource, String reportDefinitionFileName, List<String>keys)
	{
		String result = "";
		try 
		{
			//read the report definition
			ReportDefinition def = new ReportDefinition(_publishPath, reportDefinitionFileName);
			result = def.readDefinition();
			if (result.startsWith(WeaveReport.REPORT_SUCCESS))
			{
				//create the report result
				ReportResult report = ReportFactory.createReportInstance(config, def.reportType, _publishPath);
				result = report.createReport(dataSource, def, keys);
			}
		} 
		catch (Exception e) 
		{
			result = WeaveReport.REPORT_FAIL + ": " + e.getMessage();
		}
		return result;
	}


	
}
