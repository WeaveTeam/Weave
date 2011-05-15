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

import java.rmi.RemoteException;

import org.oicweave.config.ISQLConfig;

/**
 * This class exists to encapsulate the types of reports and the switch 
 * statement to create the appropriate type.  Reports are created within 
 * the web service, so the request will come in the form of a type and 
 * it's variables, so we'll have to do a switch statement on the type to create
 * the correct class type.  We encapsulate that here.  
 * 
 * Example use:
 *	AbstractReport rpt = ReportFactory.createReport(ReportType.COMPAREREPORT, dataSource, attributeNames, null);
 *	result = rpt.createReportFile("Obesity", keys);
 *
 *OR
 *	AbstractReport rpt = ReportFactory.createReport("COMPAREREPORT", dataSource, attributeNames, null);
 *  result = rpt.createReportFile("Obesity", keys);
 *
 * @author Mary Beth
 *
 */
public class ReportFactory {
	public enum ReportType 
	{ 
		CATEGORYREPORT, COMPAREREPORT;
		public static ReportType toReportType(String reportNameString) 
		throws RemoteException
		{
			try { return valueOf(reportNameString); }
			catch (Exception e) { throw new RemoteException("Unknown report type: " + reportNameString); }
		}
	};
	
	//this method converts from a string to an enum
	//we will most likely get requests through the web service 
	//using a string.  
	public static ReportResult createReportInstance(ISQLConfig config, String publishPath, String reportTypeName)
		throws RemoteException
	{
		ReportType type = ReportType.toReportType(reportTypeName);
		ReportResult rpt = null;
    	switch (type)
		{
			case CATEGORYREPORT: 
				rpt = new CategoryReport(config, publishPath);
				break;
			case COMPAREREPORT:
				/*
				List<String> indicators;
				//we allow users to send the list in either var
				if ((indicatorsA == null) && (indicatorsB != null))
					indicators = indicatorsB;
				else if ((indicatorsA != null) && (indicatorsB == null))
					indicators = indicatorsA;
				//neither is null, maybe one is empty
				else if ((indicatorsA.size() > 0) && (indicatorsB.size() == 0))
					indicators = indicatorsA;
				else if ((indicatorsA.size() == 0) && (indicatorsB.size() > 0))
					indicators = indicatorsB;
				else
					throw new RemoteException("Compare Report only uses one list of indicators, attempt to pass in two lists.");
			*/
				rpt = new CompareReport(config, publishPath);
				break;
			default: 
		    	throw new RemoteException("Report type not supported: " + type);
		}
    	rpt._reportType = type;
    	return rpt;
	}
	
	/*
	public static AbstractReport createReport(String reportTypeName, String reportName) throws RemoteException
	{
		ReportType type = ReportType.toReportType(reportTypeName);
		AbstractReport rpt = null;
		switch (type)
		{
			case TEMPLATEREPORT:
				rpt = new TemplateReport();
				break;
			default:
				throw new RemoteException("Report type not supported: " + type);
		}
		rpt._reportType = type;
		return rpt;
	}
	*/
}
