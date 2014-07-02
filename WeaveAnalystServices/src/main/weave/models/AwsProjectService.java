package weave.models;
import java.io.IOException;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.json.simple.parser.ParseException;

import weave.config.WeaveConfig;
import weave.utils.FileUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;
import weave.utils.SQLUtils.WhereClauseBuilder;

public class AwsProjectService 
{

	public AwsProjectService(){
		
	}
	
	/**
	    * @param userName author of a given Project
	    * @param projectName project which contains queryObjects
	    * @return  collection of queryObjects in the project 
	    * @throws Exception
	    */
	//retrieves all the projects belonging to a particular user
	public static String[] getProjectListFromDatabase() throws SQLException, RemoteException{
		SQLResult projectObjects= null;//all the projects belonging to the userName
		
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		
		List<String> selectColumns = new ArrayList<String>();
		selectColumns.add("projectName");//we're retrieving the list of projects in the projectName column in database
		String query = String.format("SELECT distinct(%s) FROM %s", "projectName", (SQLUtils.quoteSchemaTable(con,schema, "stored_query_objects")));
		projectObjects = SQLUtils.getResultFromQuery(con,query, null, true );
		
		String[] projectNames = new String[projectObjects.rows.length];
		for(int i = 0; i < projectObjects.rows.length; i++){
			Object project = projectObjects.rows[i][0];//TODO find better way to do this
			projectNames[i] = project.toString();

		}
		
		con.close();
		
		return projectNames;
	}
	

   /** 
   * @param projectName project from which queryObjects have to be listed
   * @return finalQueryObjectCollection array of [jsonObjects, title of queryObjects]   
   * @throws Exception
   */
//	public static AWSQueryObjectCollectionObject getQueryObjectsFromDatabase(Map<String, Object> params) throws RemoteException, SQLException
//	{
//		AWSQueryObjectCollectionObject finalQueryObjectCollection = null;
//		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
//		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
//		
//		String[] finalQueryNames= null;;
//		String[] finalQueryObjects= null;
//		String finalProjectDescription = null;
//		List<String> selectColumns = new ArrayList<String>();
//		selectColumns.add("queryObjectTitle");
//		selectColumns.add("queryObjectContent");
//		selectColumns.add("projectDescription");
//		
//		
//		Map<String,String> whereParams = new HashMap<String, String>();
//		whereParams.put("projectName", params.get("projectName").toString());
//		Set<String> caseSensitiveFields  = new HashSet<String>();//empty 
//		SQLResult queryObjectsSQLresult = SQLUtils.getResultFromQuery(con,selectColumns, schema, "stored_query_objects", whereParams, caseSensitiveFields);
//		
//		if(queryObjectsSQLresult.rows.length != 0)//run this code only if the project contains rows
//		{
//			Object[][] rows = queryObjectsSQLresult.rows;
//			finalQueryNames = new String[rows.length];
//			finalQueryObjects = new String[rows.length];
//			
//			for(int i = 0; i < rows.length; i++)
//			{
//				Object[] singleRow = rows[i];
//				finalQueryNames[i]= singleRow[0].toString();
//				finalQueryObjects[i] = singleRow[1].toString();
//				finalProjectDescription = singleRow[2].toString();
//			}
//			
//			finalQueryObjectCollection = new AWSQueryObjectCollectionObject();
//			finalQueryObjectCollection.finalQueryObjects = finalQueryObjects;
//			finalQueryObjectCollection.projectDescription = finalProjectDescription;
//			finalQueryObjectCollection.queryObjectNames = finalQueryNames;
//		
//		}//end of if statement
//		con.close();
//		return finalQueryObjectCollection;
//		
//	}
	
	/** 
	   * deletes an entire project from a database
	   * @param params map of key value pairs to construct the where clause
	   * @return count number of rows(query Objects in the project) deleted from the database
	   * @throws Exception
	   */
	public static int deleteProjectFromDatabase(Map<String, Object> params)throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams = params;
		
		WhereClauseBuilder<Object> builder = new WhereClauseBuilder<Object>(false);
		builder.addGroupedConditions(whereParams, null,null);
		WhereClause<Object> clause = builder.build(con);
		
		int count = SQLUtils.deleteRows(con, schema, "stored_query_objects",clause);
		con.close();
		return count;//number of rows deleted
	}
	
	/** 
	   * deletes a query Object from a database
	   * @param params map of key value pairs to construct the where clause
	   * @return count number of rows(query Objects) deleted from the database
	   * @throws Exception
	   */
	public static int deleteQueryObjectFromProjectFromDatabase(Map<String, Object> params)throws RemoteException, SQLException{
		
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams = params;
		
		WhereClauseBuilder<Object> builder = new WhereClauseBuilder<Object>(false);
		builder.addGroupedConditions(whereParams, null,null);
		WhereClause<Object> clause = builder.build(con);
		
		int count = SQLUtils.deleteRows(con, schema, "stored_query_objects",clause);
		con.close();
		return count;//number of rows deleted
	}
	
	/** 
	   * adds one query Objects to a project in a database
	   * @param params map of key value pairs to construct the where clause
	   * @return count number of rows(query Objects in the project) added to the database
	   * @throws Exception
	   */
	public int insertQueryObjectInProjectFromDatabase(String userName, String projectName, String queryObjectTitle, String queryObjectContent, String encodedViz) throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> record = new HashMap<String, Object>();
		record.put("userName", userName);
		record.put("projectName", projectName);
		record.put("queryObjectTitle", queryObjectTitle);
		record.put("queryObjectContent", queryObjectContent);
		record.put("resultVisualizations", encodedViz);
		
		int count = SQLUtils.insertRow(con, schema, "stored_query_objects", record );
		con.close();
		return count;//single row added
	}
	
	
	/** 
	   * adds one/more query Objects to a project in a database
	   * @param params map of key value pairs to construct the where clause
	   * @return count number of rows(query Objects in the project) added to the database
	   * @throws Exception
	   */
	public static int insertMultipleQueryObjectInProjectFromDatabase(Map<String, Object> params) throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		List<Map<String, Object>> records = new ArrayList<Map<String, Object>>();
		String[] queryObjectTitle = null;
		String[] queryObjectContent = null;
		
		//getting the queryObject titles
		 Object titlesObject = params.get("queryObjectTitle");
		 ArrayList<Object> queryObjectTitleList = new ArrayList<Object>();
		 queryObjectTitleList.add(titlesObject);
		 queryObjectTitle = queryObjectTitleList.toArray(queryObjectTitle);
		 
		 //getting the queryObject content 
		 Object contentsObject = params.get("queryObjectContent");
		 ArrayList<Object> contentList = new ArrayList<Object>();
		 contentList.add(contentsObject);
		 queryObjectContent = contentList.toArray(queryObjectContent);
		 
		
		for(int i = 0; i < queryObjectTitle.length; i++){
			Map<String,Object> record = new HashMap<String, Object>();
			record.put("userName", params.get("userName"));
			record.put("projectName", params.get("projectName"));
			record.put("projectDescription", params.get("projectDescription"));
			record.put("queryObjectTitle", queryObjectTitle[i]);
			record.put("queryObjectContent", queryObjectContent[i]);
			records.add(record);
		}
		
		
		int count = SQLUtils.insertRows(con, schema , "stored_query_objects", records );
		con.close();
		return count;
	}
	
	/** 
	   * returns list of visualizations belonging to the respective queryObjects in a project
	   * @param params project name to pull image column from (for all visualizations, project = null)
	   * @return an array of base64 strings, each encoding one image 
	   * @throws Exception
	   */
	public static AWSQueryObjectCollectionObject getListOfQueryObjects(Map<String , Object> params) throws RemoteException, SQLException
	{
		String[] visualizationCollection = null;
		String[]thumbnails;
		AWSQueryObjectCollectionObject  finalQueryObjectCollection = null;
		SQLResult visualizationSQLresult = null;
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		String[] finalQueryNames= null;;
		String[] finalQueryObjects= null;
		String finalProjectDescription = null;
		
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("projectName", params.get("projectName").toString());
		
		List<String> selectColumns = new ArrayList<String>();
		selectColumns.add("queryObjectTitle");
		selectColumns.add("queryObjectContent");
		selectColumns.add("projectDescription");
		selectColumns.add("resultVisualizations");
		Set<String> caseSensitiveFields  = new HashSet<String>();//empty 
		visualizationSQLresult = SQLUtils.getResultFromQuery(con,selectColumns, schema, "stored_query_objects", whereParams, caseSensitiveFields);
			
		//process visualizationSQLresult
		if(visualizationSQLresult.rows.length != 0)//run this code only if the project contains rows
		{
			Object[][] rows = visualizationSQLresult.rows;
			visualizationCollection = new String[visualizationSQLresult.rows.length];
			thumbnails = new String[visualizationSQLresult.rows.length];
			
			finalQueryNames = new String[rows.length];
			finalQueryObjects = new String[rows.length];
			
			for(int i = 0; i < rows.length; i++)
			{
				Object[] singleRow = rows[i];
				finalQueryNames[i]= singleRow[0].toString();
				finalQueryObjects[i] = singleRow[1].toString();
				finalProjectDescription = singleRow[2].toString();
				
				String weaveSessionString = singleRow[3].toString();
				visualizationCollection[i] = weaveSessionString;
				try {
					String oneThumbnail = FileUtils.extractFileFromArchiveBase64(weaveSessionString, "weave-files/screenshot.png");
					thumbnails[i] = oneThumbnail;
				} catch (IOException e) {
					e.printStackTrace();
				}
			}
			
			finalQueryObjectCollection = new AWSQueryObjectCollectionObject();
			finalQueryObjectCollection.finalQueryObjects = finalQueryObjects;
			finalQueryObjectCollection.projectDescription = finalProjectDescription;
			finalQueryObjectCollection.queryObjectNames = finalQueryNames;
			finalQueryObjectCollection.thumbnails = thumbnails;
			
			//for base64 screenshot taken directly
//			for(int i = 0; i < rows.length; i++){
//
//				Object singleRow = rows[i];
//				visualizationCollection[i] = singleRow;
//				System.out.print(visualizationCollection[i]);
//			}

			
			//for thumb nail extracted from weave archive file (images not very sharp)
//			for(int i = 0; i < rows.length; i++){
//				
//				Object[] singleRow = rows[i];
//				String weaveString = singleRow[0].toString();
//				try {
//					Object oneThumbnail = WeaveFileInfo.getArchiveThumbnailBase64(weaveString);
//					visualizationCollection[i] = oneThumbnail;
//					System.out.print(visualizationCollection[i]);
//				} catch (IOException e) {
//					e.printStackTrace();
//				}
//				
//			}
			
		}//end of if statement
		
		con.close();
		
		return finalQueryObjectCollection;
	}
	
	//retrives the session state of the Weave instance created by the respective query object
	public static String returnSessionState(String queryObject) throws SQLException, RemoteException, ParseException
	{
		String sessionStateString = null;
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		//JSONObject json = (JSONObject) new JSONParser().parse(queryObject);
		
		
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("queryObjectContent", queryObject);
		
		List<String> selectColumns = new ArrayList<String>();
		selectColumns.add("resultVisualizations");
		Set<String> caseSensitiveFields  = new HashSet<String>();//empty 
		
		SQLResult visualizationSQLresult = SQLUtils.getResultFromQuery(con,selectColumns, schema, "stored_query_objects", whereParams, caseSensitiveFields);
			
		//process visualizationSQLresult
		if(visualizationSQLresult.rows.length != 0)
		{
			Object[][] rows = visualizationSQLresult.rows;
			
			for(int i = 0; i < rows.length; i++)
			{
				Object[] singleRow = rows[i];
				sessionStateString= singleRow[0].toString();
				
			}
		}
		con.close();
		return sessionStateString;
	}
	
	/**
	 * This class represents a collection object that is returned to the WeaveAnalyst
	 *@param queryObjectNames names of the queryObjects belonging to a project
	 *@param finalQueryObjects the actual json objects belonging to a project
	 *@param projectDescription description of the project
	 */
	public static class AWSQueryObjectCollectionObject
	{
		String[] finalQueryObjects;
		String[] queryObjectNames;
		String projectDescription;
		String[] thumbnails;
	}
}


