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
package org.oicweave.tests;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.File;
import java.io.IOException;
import java.rmi.RemoteException;
import java.util.ArrayList;

import javax.swing.JFileChooser;
import javax.swing.JOptionPane;

import org.junit.Assert;
import org.junit.Test;
import org.oicweave.servlets.DataService;
import org.oicweave.config.ISQLConfig;
import org.oicweave.config.SQLConfigManager;
import org.oicweave.config.SQLConfigXML;
import org.oicweave.config.WeaveContextParams;
import org.oicweave.reports.ReportDefinition;
import org.oicweave.reports.ReportResult;
import org.oicweave.reports.ReportFactory;
import org.oicweave.reports.WeaveReport;

public class JUnitTestsReports {
	static DataService _dataSource = null;
	static String _configPath = null;
	static String _docrootPath = null;
	static final String _localURL = "http://localhost:8080//";
	static boolean _runTests = true;
	static ISQLConfig config;
	
	public JUnitTestsReports () throws RemoteException
	{
		if (_dataSource != null)
			return;
		int result = initPaths();
		if (result == JFileChooser.APPROVE_OPTION)
		{
			SQLConfigManager configManager = new SQLConfigManager(new WeaveContextParams(_configPath,_docrootPath));
			_dataSource = new DataService(configManager);
			config = configManager.getConfig();
			if (config == null)
				throw new RemoteException("config is null");
		}	
		else 
		{
			_runTests = false;
			throw new RemoteException("user cancelled");
		}
	}
	
	// since these tests run in JUnit - not on the server as webservices, we need 
	// to specify where the publish path is.  If it isn't in the default location, the 
	// user of the JUnit tests must specify it.   
	private int initPaths()
	{
		_configPath = "D:/tomcat/webapps/weave-config";
		_docrootPath = "D:/tomcat/webapps/ROOT";
		File sqlConfigFile = new File(_configPath, SQLConfigXML.XML_FILENAME);
		int ret = JFileChooser.APPROVE_OPTION;
		while ((! sqlConfigFile.exists()) && (ret != JFileChooser.APPROVE_OPTION)) 
		{
			String msg = _configPath + " does not exist, please select the config path to use";			
			JFileChooser fc = new JFileChooser(_configPath);
			fc.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
			JOptionPane.showMessageDialog(fc, msg, "", JOptionPane.PLAIN_MESSAGE);
			ret = fc.showOpenDialog(fc);
			if (ret == JFileChooser.APPROVE_OPTION)
			{
				_configPath = fc.getSelectedFile().getAbsolutePath();
				sqlConfigFile = new File(_configPath, SQLConfigXML.XML_FILENAME);
				if (! sqlConfigFile.exists())
					ret = JFileChooser.ERROR_OPTION;
			}
			else 
				break;
		}
		
		return ret;
	}
	@Test
	public void testObesityReportResult() throws Exception
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		ReportDefinition def = new ReportDefinition(_docrootPath, "a name that doesn't exist");
		def.reportType = ReportFactory.ReportType.COMPAREREPORT.toString();
		def.reportDataTable = "Obesity";
		ArrayList<String> indicatorsA = new ArrayList<String>();
		indicatorsA.add("Percent Obese 1995"); 
		indicatorsA.add("Percent Obese 1996"); 
		indicatorsA.add("Percent Obese 1997");
		def.indicatorsA = indicatorsA;
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("01");
		keys.add("02");
		keys.add("04");
//		try
//		{
			ReportResult reportResult = ReportFactory.createReportInstance(config, _docrootPath, def.reportType);
			String result = reportResult.createReport(_dataSource, def, keys);
			showReportInBrowser(result);
//		}
//		catch (Exception e)
//		{
//			e.printStackTrace();
//			fail(e.getMessage());
//		}
	}
	@Test
	public void testJiraReportResult() throws Exception
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		ReportDefinition def = new ReportDefinition(_docrootPath, "WeaveJiraIssues");
		def.reportType = ReportFactory.ReportType.CATEGORYREPORT.toString();
		def.reportDataTable = "Weave Jira Issues";

		ArrayList<String> categoryAttributes = new ArrayList<String>();
		categoryAttributes.add("FIXFOR");
		categoryAttributes.add("ComponentName");
		
		ArrayList<String> showAttributes = new ArrayList<String>();
		showAttributes.add("pkey");
		showAttributes.add("SUMMARY");
		showAttributes.add("DESCRIPTION");
		showAttributes.add("Rank");
		showAttributes.add("issuestatus");
		showAttributes.add("FIXFOR");
		showAttributes.add("ComponentName");

		def.indicatorsA = categoryAttributes;
		def.indicatorsB = showAttributes;
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("WV-342");
		keys.add("WVF-173");
		keys.add("WVF-152");
		keys.add("WVF-127");
//		try
//		{

			Assert.assertTrue(config != null);
			ReportResult reportResult = ReportFactory.createReportInstance(config, _docrootPath, def.reportType);
			String result = reportResult.createReport(_dataSource, def, keys);
			showReportInBrowser(result);
//		}
//		catch (Exception e)
//		{
//			e.printStackTrace();
//			fail(e.getMessage());
//		}
	}
	
	@Test
	public void testReportDefinitionFile() throws RemoteException
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		//how will this work?  
		//pass the report definition file into the factory?  
		//or - start the report by writing the header
		//use the definition to call the factory to create the report?  
		
		// the WeaveReport method opens the report definition file
		//   and reads it to get the information 
		//  WeaveReport();
		// String result = rpt.createReport(String reportName, List<String>keys)
		//  create report opens the report definition, 
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("01");
		keys.add("02");
		keys.add("04");

		WeaveReport rpt = new WeaveReport(_docrootPath);
		String result = rpt.createReport(config, _dataSource, "arandomname.html", keys);
		assertTrue("result not success: " + result, result.startsWith(WeaveReport.REPORT_SUCCESS));
		showReportInBrowser(result);
	}
	
	@Test
	public void testMissingReportDefinition() throws RemoteException
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("01");
		keys.add("02");
		keys.add("04");

		WeaveReport rpt = new WeaveReport(_docrootPath);
		String result = rpt.createReport(config, _dataSource, "a reportname that's not there", keys);
		assertTrue(result.startsWith(WeaveReport.REPORT_FAIL));
		//check for a reasonable message that tells the user that 
		//  that report definition does not exist
	}
	
	@Test
	public void testAverage()
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		if (_dataSource == null)
			return;
		ArrayList<String> data = new ArrayList<String>();
		data.add("5");
		data.add("10");
		data.add("100");
		data.add("1.22");
		data.add("N/A");
		data.add("null");
		data.add("");
		String avg = ReportResult.getAverage(data);
		assertEquals("29.06", avg);
	}

	@Test
	public void testReportDefinition()
	{
		ReportDefinition def = new ReportDefinition(_docrootPath, "arandomname.html");
		String result = def.readDefinition();
		assertTrue("result string not success: " + result, result.startsWith(WeaveReport.REPORT_SUCCESS));
	}
	
	private void showReportInBrowser(String result)
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		//make sure that we're using the correct version of assertTrue!!!
		org.junit.Assert.assertTrue("report result: " + result, 
				result.startsWith(WeaveReport.REPORT_SUCCESS));
		
		//show the report in browser window
		String reportName = result.substring(WeaveReport.REPORT_SUCCESS.length() + 1);
		
		//open it in a browser window
		String url = _localURL + WeaveReport.REPORTS_DIRECTORY + "\\" + reportName;
		try {
			Runtime.getRuntime().exec("cmd.exe /C start " + url);
		} catch (IOException e) {
			e.printStackTrace();
			fail("Server exception thrown while trying to show report: " + result + e.getMessage());
		}
		
	}
	/*
	@Test
	public void testCompareReport()
	{
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("01");
		keys.add("02");
		keys.add("04");
		String result = "";
		try
		{
			result = runObesityCompare(keys, "Obesity");
		} 
		catch (Exception e) 
		{
			fail("Server exception while creating compare report: " + result + e.getMessage());
			return;
		}
		showReportInBrowser(result);
	}
	@Test 
	public void testKeyMismatch()
	{
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("a random string");
		keys.add("another");
		keys.add("more");
		
		try
		{
			String result = runObesityCompare(keys, "Obesity");
			assertTrue("report result: " + result, 
					result.startsWith(WeaveReport.REPORT_FAIL));
		}
		catch (Exception e)
		{
			fail("server should return a fail message for a key mismatch, not throw an exception");
		}
	}
	
	@Test
	public void testMissingDataTable()
	{
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("01");
		keys.add("02");
		keys.add("04");
		String result = "";
		try
		{
			result = runObesityCompare(keys, "a random data table that doesn't exist");
		} 
		catch (Exception e) 
		{
			//shouldn't throw an exception, should return a fail message
			fail("Server exception while creating compare report: " + result + e.getMessage());
			return;
		}
		if (result.startsWith(WeaveReport.REPORT_SUCCESS))
		{
			fail("Report creation should return a fail for invalid data table. " + result);
		}
	}

*/	
/*
	private String runObesityCompare(ArrayList<String> keys, String dataTableName) throws Exception
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return "user cancelled";
		}
		if (_dataSource == null)
			return "_dataSource null";
		ArrayList<String> attributeNames = new ArrayList<String>();
		attributeNames.add("Percent Obese 1995"); 
		attributeNames.add("Percent Obese 1996"); 
		attributeNames.add("Percent Obese 1997"); 
		attributeNames.add("Percent Obese 1998"); 
		attributeNames.add("Percent Obese 1999"); 
		attributeNames.add("Percent Obese 2000"); 
		attributeNames.add("Percent Obese 2001"); 
		attributeNames.add("Percent Obese 2002"); 
		attributeNames.add("Percent Obese 2003"); 
		attributeNames.add("Percent Obese 2004"); 
		attributeNames.add("Percent Obese 2005"); 
		attributeNames.add("Percent Obese 2006"); 
		attributeNames.add("Percent Obese 2007"); 
		
		
		String result = "";
			WeaveReport rpt = ReportFactory.createReport("COMPAREREPORT", _dataSource, attributeNames, null);
			rpt.set_publishPath(_domainPath + "\\docroot");
			result = rpt.createReport(dataTableName, keys);
		return result;
	}
	
	@Test
	public void testCategoryReport()
	{
		if (! _runTests)
		{
			fail("user cancelled");
			return;
		}
		if (_dataSource == null)
			return;
		ArrayList<String> categoryAttributes = new ArrayList<String>();
		categoryAttributes.add("FIXFOR");
		categoryAttributes.add("ComponentName");
		
		ArrayList<String> showAttributes = new ArrayList<String>();
		showAttributes.add("pkey");
		showAttributes.add("SUMMARY");
		showAttributes.add("DESCRIPTION");
		showAttributes.add("Rank");
		showAttributes.add("issuestatus");
		showAttributes.add("FIXFOR");
		showAttributes.add("ComponentName");
		
		ArrayList<String> keys = new ArrayList<String>();
		keys.add("WV-342");
		keys.add("WVF-173");
		keys.add("WVF-152");
		keys.add("WVF-127");
		
		String result = "";
		try 
		{
			WeaveReport rpt = ReportFactory.createReport("CATEGORYREPORT", _dataSource, categoryAttributes, showAttributes);
			rpt.set_publishPath(_domainPath + "\\docroot");
			result = rpt.createReport("Weave Jira Issues", keys);
		} 
		catch (RemoteException e) 
		{
			fail("Server exception while creating category report: " + result + e.getMessage());
			return;
		} 
		catch (IOException e) {
			fail("Server exception while creating category report: " + result + e.getMessage());
			return;
		}
		showReportInBrowser(result);
	}
	
	*/ 
}
