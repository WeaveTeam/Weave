package infomap.admin;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import flex.messaging.cluster.RemoveNodeListener;

import infomap.servlets.GenericServlet;
import infomap.utils.ListUtils;
import infomap.utils.SQLResult;
import infomap.utils.SQLUtils;


/**
 *class SolrDataServices
 */
public class AdminService extends GenericServlet{
	private static final long serialVersionUID = 1L;
       
    private static String username;
    private static String password;
    private static String host;
    private static String port;
    private static String database;
    private static Connection conn = null;
	
	public AdminService() {
        
        getConnection();
    }
    
    private void getConnection()
    {
    	try{
    		Class.forName("com.mysql.jdbc.Driver").newInstance();
    		
    		//TODO:change these default settings to reading from a config file
    		username = "root";
    		password = "oic3Ind2";
    		host = "129.63.8.219";
    		database = "solr_sources";
    		port="3306";
    		
    		String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
    		
    	}catch (Exception e)
    	{
    		e.printStackTrace();
    	}
    	
    }
	
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
	{
    	super.doGet(request, response);
    	PrintWriter out = response.getWriter();
    	
		out.println("Deployed!");
	}
    
    synchronized public Object[][] getRssFeeds()
    {
    	if(conn == null)
		{
    		getConnection();
		}
    	
    	String query = "SELECT title,url FROM rss_feeds";
    	SQLResult result = null;
		try
		{
			result = SQLUtils.getRowSetFromQuery(conn, query);
		}
		catch (Exception e)
		{
			System.out.println(query);
			e.printStackTrace();
		}
		return  result.rows;	
    }
    
    public String addRssFeed(String title,String url) throws RemoteException
	{
		try{
			
			if(conn == null)
			{
				getConnection();
			}

			String query = "SELECT * FROM rss_feeds WHERE url = '"+ url + "'";
			
			SQLResult checkResult = SQLUtils.getRowSetFromQuery(conn, query);
			
			if (checkResult.rows.length != 0)
			{
				return "RSS Feed already exists";
			}
			
			Map<String, Object> valueMap = new HashMap<String, Object>();
			
			valueMap.put("title", title);
			valueMap.put("url", url);
			
			SQLUtils.insertRow(conn, database, "rss_feeds", valueMap);
			
			return "RSS Feed added successfully";
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
		
	}
    
    
    public String deleteRssFeed(String url) throws RemoteException
	{
    	try{
			
			if(conn == null)
			{
				getConnection();
			}
			
			
			String query = "DELETE FROM rss_feeds WHERE url = '"+ url + "'";
			
			int result = SQLUtils.getRowCountFromUpdateQuery(conn, query);
			
			return "RSS Feed was deleted";
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
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
    
    
    public void recursivelyAddFiles(String path)
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