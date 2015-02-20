package weave.servlets;

import java.nio.file.*;
import java.nio.file.attribute.*;
import java.io.*;

public class PathUtils
{
	private static final String[] ILLEGAL_CHARACTERS = { "/", "\n", "\r", "\t", "\0", "\f", "`", "?", "*", "\\", "<", ">", "|", "\"", ":" };

	public static boolean filenameIsLegal(String name)
	{
		for (int idx = 0; idx < ILLEGAL_CHARACTERS.length; idx++)
		{
			if (name.lastIndexOf(ILLEGAL_CHARACTERS[idx]) != -1) return false;
		}

		return !name.equals("..") && true;
	}
	public static boolean isChildOf(Path parent, Path child) throws IOException
	{
		parent = parent.toAbsolutePath(); /* Get the full, actual path of both arguments */
		child = child.toAbsolutePath();
		return child.startsWith(parent);
	}

	public static Path replaceExtension(Path path, String newExtension)
	{
		Path newPath = path.getParent();
		String fileName = path.getFileName().toString();
		fileName = fileName.replaceAll("\\.([a-zA-Z0-9])*$", "." + newExtension);
		return newPath.resolve(fileName);
	}
}