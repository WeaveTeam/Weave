package weave.servlets;

import java.nio.file.*;
import java.nio.file.attribute.*;

public class PathUtils
{
	private static final String[] ILLEGAL_CHARACTERS = { "/", "\n", "\r", "\t", "\0", "\f", "`", "?", "*", "\\", "<", ">", "|", "\"", ":" };

	public static boolean filenameIsLegal(String name)
	{
		for (int idx = 0; idx < ILLEGAL_CHARACTERS.length; idx++)
		{
			if (name.lastIndexOf(ILLEGAL_CHARACTERS[idx]) != -1) return false;
		}
		return true;
	}

	public static Path replaceExtension(Path path, String newExtension)
	{
		Path newPath = path.getParent();
		String fileName = path.getFileName().toString();
		fileName = fileName.replaceAll("\\.([a-zA-Z0-9])*$", "." + newExtension);
		return newPath.resolve(fileName);
	}
}