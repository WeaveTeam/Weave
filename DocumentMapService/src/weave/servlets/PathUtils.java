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

	public static boolean isChildOf(Path parent, Path child)
	{

	}

	public static Path getAnalogous(Path a, Path b)
	{

	}
}