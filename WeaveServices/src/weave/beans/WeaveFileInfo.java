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

public class WeaveFileInfo 
{
	public long lastModified = 0;
	public long fileSize 	 = 0;
	public byte[] thumb 	 = null;
	public String fileName 	 = null;

	public WeaveFileInfo(String filePath)
	{
		File weaveFile = new File(filePath);
		
		this.fileName 		= weaveFile.getName();
		this.lastModified 	= weaveFile.lastModified();
		this.fileSize 		= weaveFile.length();
		if( getExtension(fileName).equals("weave") )
		{
			try
			{
				this.thumb = getArchiveThumbnail(filePath);
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}
	}
	
	private byte[] getArchiveThumbnail(String filePath) throws IOException
	{
		ZipFile archive = new ZipFile(filePath);
		ZipEntry entry = archive.getEntry("weave-files/thumbnail.png");
		InputStream is = archive.getInputStream(entry);
		
		ByteArrayOutputStream out = new ByteArrayOutputStream();
		
		int length = 0;
		byte[] b = new byte[1024];
		while( (length = is.read(b)) >= 0 )
		{
			out.write(b, 0, length);
		}
		out.flush();
		is.close();
		out.close();
		return out.toByteArray();
	}
	
	private String getExtension(String fileName)
	{
		return fileName.substring(fileName.lastIndexOf('.')+1).toLowerCase();
	}
}
