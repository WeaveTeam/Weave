package infomap.admin;

import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;


import infomap.servlets.GenericServlet;
import infomap.utils.SQLResult;
import infomap.utils.SQLUtils;


/**
 *class SolrDataServices
 */
public class AdminService extends GenericServlet{
	private static final long serialVersionUID = 1L;
       
    private static String username = "root";
    private static String password = "oic3Ind2";
    private static String host = "129.63.8.219";
    private static String port = "3306";
    private static String database = "solr_sources";
    private Connection conn = null;
	
	public AdminService() {
        
//        getConnection();
    }
    
    private void getConnection()
    {
    	try{
    		Class.forName("com.mysql.jdbc.Driver").newInstance();
    		
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
    	String query = "SELECT title,url FROM rss_feeds";
    	SQLResult result = null;
    	Connection connection = null;
		try
		{
			String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
			connection = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
			result = SQLUtils.getRowSetFromQuery(connection, query);
			
		}
		catch (Exception e)
		{
			System.out.println(query);
			e.printStackTrace();
		}finally{
			SQLUtils.cleanup(connection);
		}
		return  result.rows;	
    }
    
    public String addRssFeed(String title,String url) throws RemoteException
	{
		try{
			
			
			String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			

			String query = "SELECT * FROM rss_feeds WHERE url = '"+ url + "'";
			
			SQLResult checkResult = SQLUtils.getRowSetFromQuery(conn, query);
			
			if (checkResult.rows.length != 0)
			{
				return "RSS Feed already exists";
			}
			
			String titleQuery = "SELECT * FROM rss_feeds WHERE title = '"+ title + "'";
			
			SQLResult checkTitleQueryResult = SQLUtils.getRowSetFromQuery(conn, titleQuery);
			
			if (checkTitleQueryResult.rows.length != 0)
			{
				return "There is already a feed with the same title. Please give a different title.";
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
			
    		String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			
			
			
			String query = "DELETE FROM rss_feeds WHERE url = '"+ url + "'";
			
			int result = SQLUtils.getRowCountFromUpdateQuery(conn, query);
			
			return "RSS Feed was deleted";
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
	}

    public String addAtomFeed(String url, String title) throws RemoteException
	{
		try{
			
			
			String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			
			Statement stat = conn.createStatement();
			
			String query = "SELECT * FROM atom_feeds WHERE url = '"+ url + "'";
			
			ResultSet checkIfExists = stat.executeQuery(query);
			
			//if url already exists then return
			if(!checkIfExists.next())
				return "Atom Feed alreadt exists";

			
			String titleQuery = "SELECT * FROM atom_feeds WHERE title = '"+ title + "'";
			
			SQLResult checkTitleQueryResult = SQLUtils.getRowSetFromQuery(conn, titleQuery);
			
			if (checkTitleQueryResult.rows.length != 0)
				return "There is already a feed with the same title. Please give a different title.";
			
			
			Map<String, Object> valueMap = new HashMap<String, Object>();
			
			valueMap.put("title", title);
			valueMap.put("url", url);
			
			SQLUtils.insertRow(conn, database, "atom_feeds", valueMap);
			
			return "Atom Feed added successfully";
			
		}catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
		
	}
    public void deleteAtomFeed(String title)
	{
		try{
			
			String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
			
			
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
			
    		String connURL = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), connURL);
			
		
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
				
	    		String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
	    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
				
			
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
			
			String url = SQLUtils.getConnectString("MySQL", host, port, database, username, password);
    		conn = SQLUtils.getConnection(SQLUtils.getDriver("MySQL"), url);
			
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
    
    public String renameFile(String filePath, String newName, Boolean overwrite)
    {
    	File file = new File(filePath);
    	 if(file.isFile())
    	 {
    		 File newFile = new File(file.getAbsolutePath()+newName);
    		 if(newFile.isFile())
    			 if(!overwrite)
    				 return "file name already exists. Give a new file name or allow overwrite.";
    			 else{
    				 newFile.delete();
    			 }
    		
    		 Boolean result = file.renameTo(newFile);
    		 if(result)
    			 return "file sucessfully renamed";
    		 else
    			 return "file rename not successful";
    	 }else{
    		 return "Given file path is not a file";
    	 }
    }
}