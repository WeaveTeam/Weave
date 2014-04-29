package weave.models;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

import weave.config.WeaveConfig;
import weave.servlets.WeaveServlet;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;
import weave.utils.SQLUtils.WhereClauseBuilder;

public class AwsProjectService extends WeaveServlet
{
	private static final long serialVersionUID = 1L;

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
	public static Object[] getQueryObjectsFromDatabase(Map<String, Object> params) throws RemoteException, SQLException
	{
		Object[] finalQueryObjectCollection = new Object[3];
		
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		
		//we're retrieving the list of queryObjects in the selected project
		List<String> selectColumns = new ArrayList<String>();
		selectColumns.add("queryObjectTitle");
		selectColumns.add("queryObjectContent");
		selectColumns.add("projectDescription");
		
		
		Map<String,String> whereParams = new HashMap<String, String>();
		whereParams.put("projectName", params.get("projectName").toString());
		Set<String> caseSensitiveFields  = new HashSet<String>();//empty 
		SQLResult queryObjectsSQLresult = SQLUtils.getResultFromQuery(con,selectColumns, schema, "stored_query_objects", whereParams, caseSensitiveFields);
		
		if(queryObjectsSQLresult.rows.length != 0)//run this code only if the project contains rows
		{
			//getting names from queryObjectTitle
			String[] queryNames =  new String[queryObjectsSQLresult.rows.length];
			String projectDescription = null;
			for(int i = 0; i < queryObjectsSQLresult.rows.length; i++){
				Object singleSQLQueryObject = queryObjectsSQLresult.rows[i][0];//TODO find better way to do this
				queryNames[i] = singleSQLQueryObject.toString();
				
			}
			projectDescription = (queryObjectsSQLresult.rows[0][2]).toString();//TODO find better way to do this
			
			//getting json objects from queryObjectContent
			JSONObject[] finalQueryObjects = null;
			if(queryObjectsSQLresult.rows.length != 0)
			{
				ArrayList<JSONObject> jsonlist = new ArrayList<JSONObject>();
				JSONParser parser = new JSONParser();
				finalQueryObjects = new JSONObject[queryObjectsSQLresult.rows.length];
				
				
				for(int i = 0; i < queryObjectsSQLresult.rows.length; i++)
				{
					Object singleObject = queryObjectsSQLresult.rows[i][1];//TODO find better way to do this
					String singleObjectString = singleObject.toString();
					try{
						
						 Object parsedObject = parser.parse(singleObjectString);
						 JSONObject currentJSONObject = (JSONObject) parsedObject;
						
						 jsonlist.add(currentJSONObject);
					}
					catch (ParseException pe){
						
					}
					
				}//end of for loop
				
				finalQueryObjects = jsonlist.toArray(finalQueryObjects);
				
			}
			else{
				finalQueryObjects = null;
			}
			
			finalQueryObjectCollection[0] = finalQueryObjects;
			finalQueryObjectCollection[1] = queryNames;
			finalQueryObjectCollection[2] = projectDescription;
		}//end of if statement
		con.close();
		return finalQueryObjectCollection;
		
	}
	
	
	public static int deleteProjectFromDatabase(Map<String, Object> params)throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		
		
		//Set<String> caseSensitiveFields  = new HashSet<String>(); 
		Map<String,Object> whereParams = new HashMap<String, Object>();
		//whereParams.put("projectName", projectName);
		whereParams = params;
		
		WhereClauseBuilder<Object> builder = new WhereClauseBuilder<Object>(false);
		builder.addGroupedConditions(whereParams, null,null);
		WhereClause<Object> clause = builder.build(con);
		
		int count = SQLUtils.deleteRows(con, schema, "stored_query_objects",clause);
		con.close();
		return count;//number of rows deleted
	}
	
	
	public static int deleteQueryObjectFromProjectFromDatabase(Map<String, Object> params)throws RemoteException, SQLException{
		
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> whereParams = new HashMap<String, Object>();
		//whereParams.put("projectName", projectName);
		//whereParams.put("queryObjectTitle", queryObjectTitle);
		whereParams = params;
		
		WhereClauseBuilder<Object> builder = new WhereClauseBuilder<Object>(false);
		builder.addGroupedConditions(whereParams, null,null);
		WhereClause<Object> clause = builder.build(con);
		
		int count = SQLUtils.deleteRows(con, schema, "stored_query_objects",clause);
		con.close();
		return count;//number of rows deleted
	}
	//adds a queryObject to the database
	public int insertQueryObjectInProjectFromDatabase(String userName, String projectName, String queryObjectTitle, String queryObjectContent) throws RemoteException, SQLException
	{
		Connection con = WeaveConfig.getConnectionConfig().getAdminConnection();
		String schema = WeaveConfig.getConnectionConfig().getDatabaseConfigInfo().schema;
		Map<String,Object> record = new HashMap<String, Object>();
		record.put("userName", userName);
		record.put("projectName", projectName);
		record.put("queryObjectTitle", queryObjectTitle);
		record.put("queryObjectContent", queryObjectContent);
		
		int count = SQLUtils.insertRow(con, schema, "stored_query_objects", record );
		con.close();
		return count;//single row added
	}
	
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

}


