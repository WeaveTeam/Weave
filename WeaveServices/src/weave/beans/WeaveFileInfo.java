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

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import weave.utils.FileUtils;

public class WeaveFileInfo 
{
	public long lastModified = 0;
	public long fileSize 	 = 0;
	public byte[] thumb 	 = null;
	public String fileName 	 = null;

	public WeaveFileInfo(String startingPath, String relativeFilePath)
	{
		File weaveFile = new File(startingPath, relativeFilePath);
		
		this.fileName 		= relativeFilePath;
		this.lastModified 	= weaveFile.lastModified();
		this.fileSize 		= weaveFile.length();
		if( getExtension(fileName).equals("weave") )
		{
			try
			{
				this.thumb = getArchiveThumbnail(weaveFile);
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}
	}
	
	private byte[] getArchiveThumbnail(File file) throws IOException
	{
		ZipFile archive = null;
		InputStream in = null;
		ByteArrayOutputStream out = null;
		try
		{
			archive = new ZipFile(file);
			ZipEntry entry = archive.getEntry("weave-files/thumbnail.png");
			in = archive.getInputStream(entry);
			out = new ByteArrayOutputStream();
			FileUtils.copy(in, out);
		}
		finally
		{
			if (in != null)
				in.close();
			if (out != null)
				out.close();
			if (archive != null)
				archive.close();
		}
		return out.toByteArray();
	}
	
	private String getExtension(String fileName)
	{
		return fileName.substring(fileName.lastIndexOf('.')+1).toLowerCase();
	}
}
