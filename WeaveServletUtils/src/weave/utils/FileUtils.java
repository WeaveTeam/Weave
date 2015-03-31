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

package weave.utils;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import org.postgresql.util.Base64;

/**
 * @author adufilie
 */
public class FileUtils
{
	public static void copy(String source, String destination) throws IOException
	{
		copy(new File(source), new File(destination));
	}
	public static void copy(File source, File destination) throws IOException
	{
		InputStream in = new FileInputStream(source);
		OutputStream out = new FileOutputStream(destination);
		copy(in, out);
	}
	public static void copy(InputStream in, OutputStream out) throws IOException
	{
		byte[] buffer = new byte[4096];
		int length;
		while ((length = in.read(buffer)) > 0)
			out.write(buffer, 0, length);
		in.close();
		out.close();
	}
	
	/**
	 * This will set readable/writable to false for everyone except the owner of the file.
	 * @param file
	 */
	public static void protect(File file)
	{
		file.setWritable(false, false);
		file.setReadable(false, false);
		file.setWritable(true, true);
		file.setReadable(true, true);
	}

	
	/**
	 * Extracts a single file from an archive.
	 * @param archiveBytesBase64 The bytes of the archive encoded as base64
	 * @param filePath The path in the archive of the file to extract
	 * @return The bytes of the extracted file encoded as base64
	 * @throws IOException
	 */
	public static String extractFileFromArchiveBase64(String archiveBytesBase64, String filePath) throws IOException
	{
		return Base64.encodeBytes(extractFileFromArchive(Base64.decode(archiveBytesBase64), filePath));
	}
	
	/**
	 * Extracts a single file from an archive.
	 * @param archiveBytes The bytes of the archive
	 * @param filePath The path in the archive of the file to extract
	 * @return The bytes of the extracted file
	 * @throws IOException
	 */
	public static byte[] extractFileFromArchive(byte[] archiveBytes, String filePath) throws IOException
	{
		File archiveFile = File.createTempFile("FileUtils-", ".zip");
		FileUtils.copy(new ByteArrayInputStream(archiveBytes), new FileOutputStream(archiveFile));
		return extractFileFromArchive(archiveFile, filePath);
	}
	
	/**
	 * Extracts a single file from an archive.
	 * @param archiveFile The archive
	 * @param filePath The path in the archive of the file to extract
	 * @return The bytes of the extracted file, or null if the file does not exist in the archive.
	 * @throws IOException
	 */
	public static byte[] extractFileFromArchive(File archiveFile, String filePath) throws IOException
	{
		ZipFile archive = null;
		InputStream in = null;
		ByteArrayOutputStream out = null;
		try
		{
			archive = new ZipFile(archiveFile);
			ZipEntry entry = archive.getEntry(filePath);
			if (entry == null)
				return null;
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
}
