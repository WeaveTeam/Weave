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

package weave.config;

import java.io.File;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;

import weave.utils.Strings;

/**
 * This class contains several parameters derived from the servlet context params in web.xml.
 * 
 * @author adufilie
 */
public class WeaveContextParams
{
	public static WeaveContextParams getInstance(ServletContext context) throws ServletException
	{
		if (_instance == null)
			_instance = new WeaveContextParams(context);
		return _instance;
	}
	private static WeaveContextParams _instance;
	
	/**
	 * This constructor is intended for testing purposes only and allows
	 * explicit values for config and docroot paths.
	 * @param configPath The path to the folder containing sqlconfig.xml
	 * @param docrootPath The path to the docroot folder.
	 */
	public WeaveContextParams(String configPath, String docrootPath)
	{
		this.docrootPath = docrootPath;
		this.configPath = configPath;
		uploadPath = configPath + "/upload/";
	}
	
	/**
	 * This constructor sets all public variables.
	 * @param context The context of a servlet containing context params.
	 */
	private WeaveContextParams(ServletContext context) throws ServletException
	{
		String contextPath = context.getRealPath("");
		String[] paths = context.getInitParameter("docrootPath").split("\\|");
		for (int i = 0; i < paths.length; i++)
		{
			File docrootFile = new File(contextPath, paths[i]);
			docrootPath = docrootFile.getAbsolutePath().replace('\\', '/') + "/";
			if (docrootFile.isDirectory())
				break;
			docrootPath = null;
		}
		if (docrootPath == null)
			throw new ServletException("ERROR: Docroot unable to be determined from servlet context path: " + contextPath);
		System.out.println("Docroot set to "+docrootPath);
		
		boolean isJetty = context.getServerInfo().startsWith("jetty");
		String configPathParam;
		if (isJetty)
			configPathParam = context.getInitParameter("configPathJetty");
		else
			configPathParam = context.getInitParameter("configPath");
		
		configPath = new File(contextPath, configPathParam).getAbsolutePath();
		configPath = configPath.replace('\\', '/');
		System.out.println("configPath set to " + configPath);
		
		uploadPath = configPath + "/upload/";
		rServePath = context.getInitParameter("RServePath");
		
		// if RServePath is not specified, keep it empty
		if (!Strings.isEmpty(rServePath))
			rServePath = new File(contextPath, rServePath).getAbsolutePath().replace('\\', '/');
		
		// make sure folders exist
		new File(configPath).mkdirs();
		new File(uploadPath).mkdirs();
	}
	
	private String docrootPath, uploadPath, configPath, rServePath;

	/**
	 * @return The docroot path, ending in "/"
	 */
	public String getDocrootPath()
	{
		return docrootPath;
	}
	/**
	 * @return The path where uploaded files are stored, ending in "/"
	 */
	public String getUploadPath()
	{
		return uploadPath;
	}
	/**
	 * @return The path where config files are stored, ending in "/"
	 */
	public String getConfigPath()
	{
		return configPath;
	}
	/**
	 * @return The path where Rserve.exe is stored
	 */
	public String getRServePath()
	{
		return rServePath;
	}
}
