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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.postgresql.util.Base64;

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
				this.thumb = getArchiveThumbnail(file);
			}
			catch (IOException e)
			{
				e.printStackTrace();
			}
		}
	}
	
	/**
	 * Gets a thumbnail from a .weave archive.
	 * @param base64 File content encoded as base64
	 * @return The thumbnail bytes encoded as base64
	 * @throws IOException
	 */
	public static String getArchiveThumbnailBase64(String base64) throws IOException
	{
		return Base64.encodeBytes(getArchiveThumbnail(Base64.decode(base64)));
	}
	
	/**
	 * Gets a thumbnail from a .weave archive.
	 * @param bytes File content
	 * @return The thumbnail bytes
	 * @throws IOException
	 */
	public static byte[] getArchiveThumbnail(byte[] bytes) throws IOException
	{
		File file = File.createTempFile("weave-", ".weave");
		FileUtils.copy(new ByteArrayInputStream(bytes), new FileOutputStream(file));
		return getArchiveThumbnail(file);
	}
	
	/**
	 * Gets a thumbnail from a .weave archive.
	 * @param file The .weave file
	 * @return The thumbnail bytes
	 * @throws IOException
	 */
	public static byte[] getArchiveThumbnail(File file) throws IOException
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
