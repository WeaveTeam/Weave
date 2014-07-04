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

package weave.beans;

import java.io.File;
import java.io.IOException;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathFactory;

import org.postgresql.util.Base64;
import org.w3c.dom.Document;
import org.xml.sax.SAXException;

import weave.utils.FileUtils;
import weave.utils.Strings;
import weave.utils.XMLUtils;

public class WeaveFileInfo 
{
	public long lastModified = 0;
	public long fileSize 	 = 0;
	public byte[] thumb 	 = null;
	public String fileName 	 = null;

	public WeaveFileInfo(File file)
	{
		init(file);
	}
	
	public WeaveFileInfo(String startingPath, String relativeFilePath)
	{
		init(new File(startingPath, relativeFilePath));
		fileName = relativeFilePath;
	}
	
	private void init(File file)
	{
		fileName = file.getName();
		lastModified = file.lastModified();
		fileSize = file.length();
		try
		{
			String ext = getExtension(fileName);
			if (ext.equals("xml"))
			{
				Document doc = XMLUtils.getXMLFromFile(file);
				XPath xpath = XPathFactory.newInstance().newXPath();
				String ascii = XMLUtils.getStringFromXPath(doc, xpath, "//ByteArray[@name = \"thumbnail.png\" and @encoding = \"base64\"]");
				if (!Strings.isEmpty(ascii))
					this.thumb = Base64.decode(ascii);
			}
			else if (ext.equals("weave"))
			{
				this.thumb = FileUtils.extractFileFromArchive(file, "weave-files/thumbnail.png");
			}
		}
		catch (IOException e)
		{
			e.printStackTrace();
		}
		catch (ParserConfigurationException e)
		{
			e.printStackTrace();
		}
		catch (SAXException e)
		{
			e.printStackTrace();
		}
	}
	
	private String getExtension(String fileName)
	{
		return fileName.substring(fileName.lastIndexOf('.')+1).toLowerCase();
	}
}
