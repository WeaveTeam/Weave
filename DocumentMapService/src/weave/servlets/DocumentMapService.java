package weave.servlets;

import java.util.Map;
import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
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
	public void createCollection(String name) throws RemoteException
	{
		try 
		{
			getCollection(name).create();
		}
		catch (IOException e)
		{
			throw new RemoteException("Failed to create collection.", e);
		}
	}

	public void deleteCollection(String name) throws RemoteException
	{
		try
		{
			getCollection(name).remove();
		}
		catch (IOException e)
		{
			throw new RemoteException("Failed to delete collection.", e);
		}
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
			throw new RemoteException("Failed to list collections:", e);
		}

	}

	private byte[] getMagicBytes(InputStream stream) throws IOException
	{
		stream.mark(5);
		byte[] magic = new byte[4];
		stream.reset();

		return magic;
	}
	private final byte[] PDF_BYTES = {(byte)0x25, (byte)0x50, (byte)0x44, (byte)0x46};
	private final byte[] ZIP_BYTES = {(byte)0x50, (byte)0x4B, (byte)0x03, (byte)0x04};

	public void addDocuments(String collectionName, String fileName, InputStream fileStream) throws RemoteException
	{
		try 
		{
			if (Arrays.equals(getMagicBytes(fileStream), PDF_BYTES))
				getCollection(collectionName).addDocument(fileName, fileStream);
			else if (Arrays.equals(getMagicBytes(fileStream), ZIP_BYTES))
				getCollection(collectionName).addZip(fileName, fileStream);
		}
		catch (IOException e)
		{
			throw new RemoteException("Failed to add document:", e);
		}
	}

	public void extractText(String collectionName, boolean force) throws RemoteException
	{
		try
		{
			getCollection(collectionName).extractText(force);
		}
		catch (IOException e)
		{
			throw new RemoteException("Failed to extract text:", e);
		}
	}

	public void updateMalletDb(String collectionName, boolean force) throws RemoteException
	{
		try
		{
			getCollection(collectionName).updateMalletDb(force);
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to import content into mallet database.", e);
		}
	}

	public void buildTopicModel(String collectionName, int topicCount) throws RemoteException
	{
		try
		{
			getCollection(collectionName).buildTopicModel(topicCount);
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to build topic model:", e);
		}
	}

	public void buildThumbnails(String collectionName, boolean force) throws RemoteException
	{
		try
		{
			getCollection(collectionName).renderThumbnails(force);
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to render thumbnails:", e);
		}
	}

	// docID -> title
	public Map<String,String> getTitles(String collectionName) throws RemoteException
	{
		try
		{
			return getCollection(collectionName).getTitles();
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to get titles.");
		}
	}
	
	// topicID -> list of words for that topic
	public Map<String,List<String>> getTopics(String collectionName) throws RemoteException
	{
		try
		{
			return getCollection(collectionName).getTopics(10);
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to get topics.");
		}
	}

	// docID -> (topicID -> Double)
	public Map<String,Map<String,Double>> getTopicWeights(String collectionName) throws RemoteException
	{
		try
		{
			return getCollection(collectionName).getTopicWeights();
		}
		catch (Exception e)
		{
			throw new RemoteException("Failed to get topic weights.");
		}
	}
}