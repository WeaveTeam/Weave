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
		String[] paths = context.getInitParameter("docrootPath").split("\\|");
		for (int i = 0; i < paths.length; i++)
		{
			docrootPath = context.getRealPath(paths[i]).replace('\\', '/') + "/";
			if (new File(docrootPath).isDirectory())
				break;
			docrootPath = null;
		}
		if (docrootPath == null)
			throw new ServletException("ERROR: Docroot unable to be determined from servlet context path: " + context.getRealPath(""));
		System.out.println("Docroot set to "+docrootPath);
		
		configPath = context.getRealPath(context.getInitParameter("configPath")).replace('\\', '/');
		uploadPath = configPath + "/upload/";
		rServePath = context.getInitParameter("RServePath");
		
		// if RServePath is not specified, keep it empty
		if (!Strings.isEmpty(rServePath))
			rServePath = context.getRealPath(rServePath).replace('\\', '/');
		
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
