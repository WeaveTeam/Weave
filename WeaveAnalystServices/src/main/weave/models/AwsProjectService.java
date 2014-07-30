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

import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import weave.config.WeaveConfig;
import weave.servlets.WeaveServlet;
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
	public String[] getProjectListFromDatabase() throws SQLException, RemoteException{
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
	   * deletes an entire project from a database
	   * @param params map of key value pairs to construct the where clause
	   * @return count number of rows(query Objects in the project) deleted from the database
	   * @throws Exception
	   */
	public int deleteProjectFromDatabase(String projectName)throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("projectName", projectName);
		
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
	public int deleteQueryObjectFromProject(String projectName, String queryObjectTitle) throws RemoteException, SQLException{
		
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("projectName", projectName);
		whereParams.put("queryObjectTitle", queryObjectTitle);
		
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
	public int insertQueryObjectInProjectFromDatabase(String userName,
													  String projectName,
													  String projectDescription,
													  String queryObjectTitle,
													  String queryObjectContent, 
													  String encodedViz) throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> record = new HashMap<String, Object>();
		record.put("userName", userName);
		record.put("projectName", projectName);
		record.put("projectDescription", projectDescription);
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
	public int insertMultipleQueryObjectInProjectFromDatabase(String userName, 
															  String projectName,
															  String projectDescription,
															  String[] queryObjectTitles,
															  String[] queryObjectContent,
															  String resultVisualizations) throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		List<Map<String, Object>> records = new ArrayList<Map<String, Object>>();
		
		for(int i = 0; i < queryObjectTitles.length; i++){
			Map<String,Object> record = new HashMap<String, Object>();
			record.put("userName",userName);
			record.put("projectName", projectName);
			record.put("projectDescription", projectDescription);
			record.put("queryObjectTitle", queryObjectTitles[i]);
			record.put("queryObjectContent", queryObjectContent[i]);
			record.put("resultVisualizations",resultVisualizations);
			records.add(record);
		}
		
		int count = SQLUtils.insertRows(con, schema , "stored_query_objects", records );
		con.close();
		return count;
	}
	
	/** 
	   * returns a list of query Objects in a project
	   * @param params project name to pull image column from (for all visualizations, project = null)
	   * @returns an array of AWSQueryObjectCollection objects one each for every queryObject 
	   * @throws Exception
	   */
	public AWSQueryObjectCollection[] getListOfQueryObjects(String  projectName) throws RemoteException, SQLException
	{
		AWSQueryObjectCollection[]  finalQueryObjectCollection = null;
		SQLResult visualizationSQLresult = null;
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		
		Map<String,Object> whereParams = new HashMap<String, Object>();
		whereParams.put("projectName", projectName);
		
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
			finalQueryObjectCollection = new AWSQueryObjectCollection[rows.length];
			
			for(int i = 0; i < rows.length; i++)
			{
				AWSQueryObjectCollection singleObject = new AWSQueryObjectCollection();
				
				Object[] singleRow = rows[i];
				singleObject.queryObjectName= singleRow[0].toString();
				singleObject.finalQueryObject = singleRow[1];
				singleObject.projectDescription = singleRow[2].toString();
				
				if(singleRow[3] != null){//when the queryobject does not contain an associated weave session state
						String weaveSessionString = singleRow[3].toString();
					try {
						String oneThumbnail = FileUtils.extractFileFromArchiveBase64(weaveSessionString, "weave-files/screenshot.png");
						singleObject.thumbnail = oneThumbnail;
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
				else{
					singleObject.thumbnail = null;
				}
				
				finalQueryObjectCollection[i] = singleObject;
			}
			

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
	
	/** 
	   * returns the session state of the Weave instance created by the query object
	   * @param params queryObject json string that represents a queryObject
	   * @returns a base64 string representing the session state
	   * @throws Exception
	   */
	public String getSessionState(String queryObject) throws SQLException, RemoteException
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
	   * writes the session state of the Weave instance created by the query object, adds it as a property to the queryObject
	   * @param params queryObject json string that represents a queryObject
	   * @returns the number of rows successfully added or updated
	   * @throws Exception
	   */
	//public static int writeSessionState(Map<String, Object> params)throws RemoteException, SQLException
	public int writeSessionState( String userName,
								 String projectDescription,
								 String queryObjectTitles,
								 String queryObjectJsons,
								 String resultVisualizations,
								 String projectName)throws RemoteException, SQLException
	{
		int count; 
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		
		Map<String,Object> whereParams = new HashMap<String, Object>();
		//whereParams.put("projectName", projectName);
		whereParams.put("queryObjectContent", queryObjectJsons);
		
		List<String> selectColumns = new ArrayList<String>();
		//selectColumns.add("projectName");
		selectColumns.add("queryObjectContent");
		Set<String> caseSensitiveFields  = new HashSet<String>();//empty 
		//check if queryObject exists
		SQLResult checkExistStatus = SQLUtils.getResultFromQuery(con,selectColumns, schema, "stored_query_objects", whereParams, caseSensitiveFields ) ;
		if(checkExistStatus.rows.length > 0)
		{			//if yes then update
			
			String dbTable = SQLUtils.quoteSchemaTable(con,schema, "stored_query_objects");
			
			Map<String, Object> dataUpdate = new HashMap<String, Object>();
			dataUpdate.put("resultVisualizations", resultVisualizations);
			
			count = SQLUtils.updateRows(con, schema, dbTable, whereParams, dataUpdate, caseSensitiveFields);	
		}
		else{
			//else insert new row
			count = insertQueryObjectInProjectFromDatabase(userName, projectName,projectDescription,queryObjectTitles,queryObjectJsons,resultVisualizations);
		}
		return count;
	}
	
	/**
	 * This class represents a collection object that is returned to the WeaveAnalyst
	 *@param queryObjectNames name of the queryObject
	 *@param finalQueryObject the actual json object 
	 *@param projectDescription description of the project to which the query object belongs
	 *@param thumnail base64 string of the snapshot of the session state generated by running a queryObject
	 */
	public static class AWSQueryObjectCollection
	{
		Object finalQueryObject;
		String queryObjectName;
		String projectDescription;
		String thumbnail;
	}
}


