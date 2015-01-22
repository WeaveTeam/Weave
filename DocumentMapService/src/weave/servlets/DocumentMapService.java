package weave.servlets;

import javax.servlet.http.HttpServletRequest;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.io.*;
import java.nio.file.*;
import java.nio.file.attribute.*;
import javax.servlet.*;
import javax.servlet.http.*;
import java.rmi.RemoteException;


public class DocumentMapService extends WeaveServlet
{
	private static final String UPLOAD_PATH = "uploads";
	private static final String MALLET_MODEL_PATH = "mallet";
	private static final String DOCUMENT_PATH = "documents";

	ServletConfig config;


	public void init(ServletConfig config) throws ServletException 
	{
		this.config = config;
		super.init(config);
	}
	public boolean createCollection(String name) throws RemoteException
	{
		try 
		{
			if (!filenameIsLegal(name)) return false;
			ServletContext application = config.getServletContext();
			Path collectionPath = Paths.get(application.getInitParameter("collectionsPath"), name);
			if (Files.exists(collectionPath)) return false;
			Files.createDirectories(collectionPath);
			Files.createDirectories(collectionPath.resolve(UPLOAD_PATH));
			Files.createDirectories(collectionPath.resolve(MALLET_MODEL_PATH));
			Files.createDirectories(collectionPath.resolve(DOCUMENT_PATH));
			return true;
		}
		catch (Exception e)
		{
			throw new RemoteException("", e);
		}
	}

	public boolean deleteCollection(String name) throws RemoteException
	{
		
		try
		{
			if (!filenameIsLegal(name)) return false;
				ServletContext application = config.getServletContext();
				Path collectionPath = Paths.get(application.getInitParameter("collectionsPath"), name);
				if (!Files.exists(collectionPath)) return false;
				Files.walkFileTree(collectionPath, new SimpleFileVisitor<Path>() {
					@Override
					public FileVisitResult visitFile(Path file, BasicFileAttributes attrs)
					 throws IOException
					{
					 Files.delete(file);
					 return FileVisitResult.CONTINUE;
					}
					@Override
					public FileVisitResult postVisitDirectory(Path dir, IOException e)
					 throws IOException
					{
					 if (e == null) {
					     Files.delete(dir);
					     return FileVisitResult.CONTINUE;
					 } else {
					     // directory iteration failed
					     throw e;
					 }
					}
				});
		}
		catch (Exception e)
		{
			throw new RemoteException("", e);
		}
		return true;
	}

	public String[] listCollections() throws RemoteException
	{
		try
		{
			ServletContext application = config.getServletContext();
				Path collectionsPath = Paths.get(application.getInitParameter("collectionsPath"));
				ArrayList<String> collectionList = new ArrayList<String>();
				try (DirectoryStream<Path> stream = Files.newDirectoryStream(collectionsPath, "*.{c,h,cpp,hpp,java}")) {
					for (Path entry: stream) {
						entry.getFilename()
						collectionList.add(entry.getFileName().toString());
					}
				} catch (DirectoryIteratorException ex) {
					// I/O error encounted during the iteration, the cause is an IOException
					throw ex.getCause();
				}
				return collectionList.toArray(new String[1]);
		}
		catch (Exception e)
		{
			throw new RemoteException("", e);
		}

	}

	public boolean addDocuments(String collectionName, String fileName, InputStream fileStream) throws RemoteException
	{
		/* TODO: Reject names with filesystem special characters */

		return true;
	}

	public boolean removeDocuments(String collectionName, String documentPath) throws RemoteException
	{
		/* TODO: Reject names with filesystem special characters */
		return true;
	}

	public boolean runTopicGeneration(String collectionName, int topicCount) throws RemoteException
	{
		return true;
	}

	public boolean runTopicLayout(String collectionName) throws RemoteException
	{
		return true;
	}

	private static final String[] ILLEGAL_CHARACTERS = { "/", "\n", "\r", "\t", "\0", "\f", "`", "?", "*", "\\", "<", ">", "|", "\"", ":" };
	private static boolean filenameIsLegal(String name)
	{
		for (int idx = 0; idx < ILLEGAL_CHARACTERS.length; idx++)
		{
			if (name.lastIndexOf(ILLEGAL_CHARACTERS[idx]) != -1) return false;
		}
		return true;
	}
}