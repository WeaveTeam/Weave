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
