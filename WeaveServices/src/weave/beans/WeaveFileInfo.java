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

import weave.utils.FileUtils;

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
		if (getExtension(fileName).equals("weave"))
		{
			try
			{
				this.thumb = FileUtils.extractFileFromArchive(file, "weave-files/thumbnail.png");
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}
	}
	
	private String getExtension(String fileName)
	{
		return fileName.substring(fileName.lastIndexOf('.')+1).toLowerCase();
	}
}
