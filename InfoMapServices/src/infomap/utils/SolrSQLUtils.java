package infomap.utils;

import java.io.File;
import java.lang.reflect.Array;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;


/**
 *class SolrDataServices
 */
public class SolrSQLUtils {
	private static final long serialVersionUID = 1L;
       
    private static String username;
    private static String password;
    private static String host;
    private static String port;
    private static String database;
    private static Connection conn = null;
	
	public SolrSQLUtils() {
        
        getConnection();
    }
    
    public void getConnection()
    {
    	try{
    		Class.forName("com.mysql.jdbc.Driver").newInstance();
    		
    		//TODO:change these default settings to reading from a config file
    		username = "root";
    		password = "oic3Ind2";
    		host = "129.63.8.219";
    		database = "solr_sources";
    		
    		String url = "jdbc:mysql://" + host + "/" + database +
    		"?user=" + username + "&password=" + password;
    		
    		conn = DriverManager.getConnection(url);
    		
    	}catch (Exception e)
    	{
    		e.printStackTrace();
    	}
    	
    }
	
    public void addRssFeed(String url, String title)
	{
		try{
			
			if(conn == null)
			{
				getConnection();
			}
			Statement stat = conn.createStatement();

			String query = "SELECT * FROM rss_feeds WHERE url = '"+ url + "'";
			
			ResultSet checkIfExists = stat.executeQuery(query);
			
			//if url already exists then return
			if(!checkIfExists.next())
				return;
			
			String insertRssFeed = "INSERT INTO rss_feeds (url,title) VALUE ('"+ url+"','"+title+"')";
			
			int result = stat.executeUpdate(insertRssFeed);
			
			System.out.println("adding rss feed : " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
		
	}
    public void deleteRssFeed(String title)
	{
		try{
			
			if(conn == null)
			{
				getConnection();
			}
			
			String deleteFileSource = "DELETE FROM rss_feeds WHERE titile ='"+title+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(deleteFileSource);
			
			System.out.println("deleting rss feed: " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
	}

    public void addAtomFeed(String url, String title)
	{
		try{
			
			if(conn == null)
			{
				getConnection();
			}
			
			Statement stat = conn.createStatement();
			
			String query = "SELECT * FROM atom_feeds WHERE url = '"+ url + "'";
			
			ResultSet checkIfExists = stat.executeQuery(query);
			
			//if url already exists then return
			if(!checkIfExists.next())
				return;
			
			String insertAtomFeed = "INSERT INTO atom_feeds (url,title) VALUE ('"+ url+"','"+title+"')";
			
			int result = stat.executeUpdate(insertAtomFeed);
			
			System.out.println("adding atom feed : " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
		
	}
    public void deleteAtomFeed(String title)
	{
		try{
			
			if(conn == null)
			{
				getConnection();
			}
			
			String deleteFileSource = "DELETE FROM atom_feeds WHERE titile ='"+title+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(deleteFileSource);
			
			System.out.println("deleting atom feed: " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
	}
    
    public void addFilePath(String url, String title)
	{
    	try{
			
			if(conn == null)
			{
				getConnection();
			}
		
		String insertFileSource = "INSERT INTO file_sources (url,title) VALUE ('"+ url+"','"+title+"')";
		
		Statement stat = conn.createStatement();
		int result = stat.executeUpdate(insertFileSource);
		
		System.out.println("adding file path : " + result);
			
		recursivelyAddFiles(url);
		
    	}catch(Exception e)
    	{
    		e.printStackTrace();
    	}
			
		
	}
    
    
    private void recursivelyAddFiles(String path)
    {
    	
    	File file = new File(path);
		
		if(file.isFile())
		{
	    	try{
				
				if(conn == null)
				{
					getConnection();
				}
			
			String insertFileSource = "INSERT INTO file_paths (url,title) VALUE ('"+ path+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(insertFileSource);
			
			System.out.println("adding file path : " + result);
			
			stat.close();
			conn.close();
		
			}catch (Exception e)
			{
				e.printStackTrace();
			}
		}else if(file.isDirectory())
		{
			String[] fileList = file.list();
			
			for(int i=0; i<fileList.length; i++)
			{
				recursivelyAddFiles(path+"/"+fileList[i]);
			}
			
		}
	
    

	}
    
    public void deleteFilePath(String title)
	{
		try{
			
			if(conn == null)
			{
				getConnection();
			}
			
			String deleteFileSource = "DELETE FROM file_sources WHERE titile ='"+title+"')";
			
			Statement stat = conn.createStatement();
			int result = stat.executeUpdate(deleteFileSource);
			
			System.out.println("deleting file path : " + result);
			
			stat.close();
			conn.close();
			
		}catch (Exception e)
		{
			e.printStackTrace();
		}
		
	}
}