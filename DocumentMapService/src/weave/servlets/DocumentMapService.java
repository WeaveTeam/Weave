package weave.servlets;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.io.*;
import java.nio.file.*;
import java.nio.file.attribute.*;
import java.nio.charset.Charset;
import javax.servlet.*;
import javax.servlet.http.*;
import java.rmi.RemoteException;
import weave.servlets.documentmap.DocumentCollection;


public class DocumentMapService extends WeaveServlet
{


	private ServletConfig config;

	public void init(ServletConfig config) throws ServletException 
	{
		this.config = config;
		super.init(config);
	}
	private DocumentCollection getCollection(String name)
	{
		ServletContext application = config.getServletContext();
		return new DocumentCollection(Paths.get(application.getInitParameter("collectionsPath"), name));
	}
	public boolean createCollection(String name) throws RemoteException
	{
		try 
		{
			return getCollection(name).create();
		}
		catch (Exception e)
		{
			throw new RemoteException("", e);
		}
		return false;
	}

	public boolean deleteCollection(String name) throws RemoteException
	{
		try
		{
			return getCollection(name).remove();
		}
		catch (Exception e)
		{
			throw new RemoteException("", e);
		}
		return false;
	}

	public String[] listCollections() throws RemoteException
	{
		try
		{
			ServletContext application = config.getServletContext();
			Path collectionsPath = Paths.get(application.getInitParameter("collectionsPath"));
			ArrayList<String> collectionList = new ArrayList<String>();
			try (DirectoryStream<Path> stream = Files.newDirectoryStream(collectionsPath)) {
				for (Path entry: stream) {
					collectionList.add(entry.getFileName().toString());
				}
			} catch (DirectoryIteratorException ex) {
				// I/O error encounted during the iteration, the cause is an IOException
				throw ex.getCause();
			}
			return collectionList.toArray(new String[0]);
		}
		catch (Exception e)
		{
			throw new RemoteException("", e);
		}

	}

	private byte[] getMagicBytes(InputStream stream)
	{
		stream.mark();
		byte[] magic = new byte[4];
		stream.reset();

		return magic;
	}
	private const byte[] PDF_BYTES = {(byte)0x25, (byte)0x50, (byte)0x44, (byte)0x46};
	private const byte[] ZIP_BYTES = {(byte)0x50, (byte)0x4B, (byte)0x03, (byte)0x04};

	public int addDocuments(String collectionName, String fileName, InputStream fileStream) throws RemoteException
	{

		if (Array.equals(getMagicBytes(fileStream), PDF_BYTES))
			return getCollection(collectionName).addDocument(fileName, fileStream);
		else if (Array.equals(getMagicBytes(fileStream), ZIP_BYTES))
			return getCollection(collectionName).addZip(fileName, fileStream);
		return 0;
	}

	public boolean extractText(String collectionName, boolean force) throws RemoteException
	{
		return getCollection(collectionName).extractText(force);
	}



	public boolean buildTopicModel(String collectionName, int topicCount) throws RemoteException
	{
	}

	public boolean buildTopicWeights(String collectionName) throws RemoteException
	{
	}

	public boolean buildThumbnails(String collectionName, boolean force)
	{
	}

	public boolean buildTopicWeights(String collectionName)
	{
	}

	public List<Map<String,Number>> getTopicLayout(String collectionName)
	{
		return null;
	}

	public List<Map<String,Number>> getDocumentTopics(String collectionName)
	{
		return null;
	}

	private static 
}