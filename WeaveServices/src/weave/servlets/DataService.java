/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.servlets;

import java.io.IOException;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.beans.AttributeColumnDataWithKeys;
import weave.beans.DataServiceMetadata;
import weave.beans.DataTableMetadata;
import weave.beans.GeometryStreamMetadata;
import weave.beans.WeaveRecordList;
import weave.config.ISQLConfig;
import weave.config.ISQLConfig.AttributeColumnInfo;
import weave.config.ISQLConfig.DataType;
import weave.config.ISQLConfig.PrivateMetadata;
import weave.config.ISQLConfig.PublicMetadata;
import weave.config.SQLConfigManager;
import weave.geometrystream.SQLGeometryStreamReader;
import weave.reports.WeaveReport;
import weave.utils.CSVParser;
import weave.utils.ListUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;

/**
 * This class connects to a database and gets data
 * uses xml configuration file to get connection/query info
 * 
 * @author Andy Dufilie
 */
public class DataService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	private SQLConfigManager configManager;
	
	public DataService()
	{
	}
	
	/**
	 * This constructor is for testing only.
	 * @param configManager
	 */
	public DataService(SQLConfigManager configManager)
	{
		this.configManager = configManager;
	}

	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		configManager = SQLConfigManager.getInstance(config.getServletContext());
	}
	
	public DataServiceMetadata getDataServiceMetadata()
		throws RemoteException
	{
		//TODO
		return null;
		/*
		configManager.detectConfigChanges();
		
		ISQLConfig config = configManager.getConfig();
		String[] tableNames = config.getDataTableNames(null).toArray(new String[0]);
		String[] geomNames = config.getGeometryCollectionNames(null).toArray(new String[0]);
		String[] geomKeyTypes = new String[geomNames.length];
		for (int i = 0; i < geomNames.length; i++)
			geomKeyTypes[i] = config.getGeometryCollectionInfo(geomNames[i]).keyType;
		
		@SuppressWarnings("unchecked")
		Map<String,String>[] tableMetadata = new Map[tableNames.length];
		// get dublin core metadata
		for (int i = 0; i < tableNames.length; i++)
		{
			// get dublin core metadata
			try
			{
				DatabaseConfigInfo configInfo = config.getDatabaseConfigInfo();
				String configConnectionName = configInfo.connection;
				String schema = configInfo.schema;
				Connection conn = SQLConfigUtils.getConnection(config, configConnectionName);
				tableMetadata[i] = DublinCoreUtils.listDCElements(conn, schema, tableNames[i]);
				tableMetadata[i].put(PublicMetadata.NAME, tableNames[i]);
			}
			catch (SQLException e)
			{
				throw new RemoteException("Unable to connect to database", e);
			}
		}
		
		return new DataServiceMetadata(config.getServerName(), tableMetadata, geomNames, geomKeyTypes);
		*/
	}
	
	public DataTableMetadata getDataTableMetadata(String dataTableName)
		throws RemoteException
	{
		//TODO
		return null;
		/*
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		
		if (dataTableName == null || dataTableName.length() == 0)
			return null;
		
		boolean geometryCollectionExists = ListUtils.findString(dataTableName, config.getGeometryCollectionNames(null)) >= 0;
		List<AttributeColumnInfo> infoList = config.getAttributeColumnInfo(dataTableName);
		if (infoList.size() == 0 && !geometryCollectionExists)
			throw new RemoteException("DataTable \""+dataTableName+"\" does not exist.");
		
		Map<String,String>[] metadata = new Map[infoList.size()];
		for (int i = 0; i < infoList.size(); i++)
			metadata[i] = infoList.get(i).getAllMetadata(); // everything in metadata is public (no SQL info)
		
		// prepare result object
		DataTableMetadata result = new DataTableMetadata();
		
		result.setGeometryCollectionExists(geometryCollectionExists);
		if (geometryCollectionExists)
		{
			GeometryCollectionInfo info = config.getGeometryCollectionInfo(dataTableName);
			
			result.setGeometryCollectionKeyType(info.keyType);
			result.setGeometryCollectionProjectionSRS(info.projection);
		}
		result.setColumnMetadata(metadata);

		return result;
		*/
	}
	
	@SuppressWarnings("unchecked")
	public WeaveRecordList getRows(String keyType, String[] keysArray) throws RemoteException
	{
		List<String> keys = new ArrayList<String>();
		keys = ListUtils.copyArrayToList(keysArray, keys);
		HashMap<String,String> params = new HashMap<String,String>();
		params.put(PublicMetadata.KEYTYPE,keyType);
	        AttributeColumnInfo tmpinfo = new AttributeColumnInfo();
                tmpinfo.publicMetadata = params;	
		HashMap<String,Integer> keyMap = new HashMap<String,Integer>();
		for (int keyIndex = 0; keyIndex < keysArray.length; keyIndex ++ )
			keyMap.put( keysArray[keyIndex],keyIndex);
		
		int rowIndex =0;
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(tmpinfo);
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		if (infoList.size() > 100)
			infoList = infoList.subList(0, 100);
		
		Object recordData[][] =  new Object[keys.size()][infoList.size()];
		
		Map<String,String> metadataList[] = new Map[infoList.size()];
		for (int colIndex = 0; colIndex < infoList.size(); colIndex++)
		{
			AttributeColumnInfo info = infoList.get(colIndex);
			String connectionName = info.privateMetadata.get(PrivateMetadata.CONNECTION);
			String sqlQuery = info.privateMetadata.get(PrivateMetadata.SQLQUERY);
			String sqlParams = info.privateMetadata.get(PrivateMetadata.SQLPARAMS);
			metadataList[colIndex] = info.publicMetadata;

			//if (dataWithKeysQuery.length() == 0)
			//	throw new RemoteException(String.format("No SQL query is associated with column \"%s\" in dataTable \"%s\"", attributeColumnName, dataTableName));
			
			List<Double> numericData = null;
			List<String> stringData = null;
			List<String> secKeys = new ArrayList<String>();
			String dataType = info.publicMetadata.get(PublicMetadata.DATATYPE);
			boolean hasSecondaryKey = true;
			
			// use config min,max or param min,max to filter the data
			String infoMinStr = info.publicMetadata.get(PublicMetadata.MIN);
			String infoMaxStr = info.publicMetadata.get(PublicMetadata.MAX);
			double minValue = Double.NEGATIVE_INFINITY;
			double maxValue = Double.POSITIVE_INFINITY;
			// first try parsing config min,max values
			try { minValue = Double.parseDouble(infoMinStr); } catch (Exception e) { }
			try { maxValue = Double.parseDouble(infoMaxStr); } catch (Exception e) { }
			// override config min,max with param values if given
			
			/**
			 * columnInfoArray = config.getAttributeColumnInfo(params);
			 * for each info in columnInfoArray
			 *      get sql data
			 *      for each row in sql data
			 *            if key is in keys array,
			 *                  add this value to the result
			 * return result
			 */
			
			try
			{
				//timer.start();
				
				SQLResult result;
				if (sqlParams != null && sqlParams.length() > 0)
				{
					String[] sqlParamsArray = CSVParser.defaultParser.parseCSV(sqlParams)[0];
					result = SQLUtils.getRowSetFromQuery(config.getNamedConnection(connectionName, true), sqlQuery, sqlParamsArray);
				}
				else
				{
					result = SQLUtils.getRowSetFromQuery(config.getNamedConnection(connectionName, true), sqlQuery);
				}
				//timer.lap("get row set");
				// if dataType is defined in the config file, use that value.
				// otherwise, derive it from the sql result.
				if (dataType.length() == 0)
					dataType = DataType.fromSQLType(result.columnTypes[1]);
				if (dataType.equalsIgnoreCase(DataType.NUMBER)) // special case: "number" => Double
					numericData = new ArrayList<Double>();
				else // for every other dataType, use String
					stringData = new ArrayList<String>();
				
				Object keyObj, dataObj;
				double value;
				
				for( int i = 0; i < result.rows.length; i++)
				{
					keyObj = result.rows[i][0];
					if(keyMap.get(keyObj)!= null){
						rowIndex = keyMap.get(keyObj);
						if (keyObj == null)
							continue;
			
						if (numericData != null)
						{
							if (result.rows[i][1] == null)
								continue;
							try
							{
								value = ((Double)result.rows[i][1]).doubleValue();
							}
							catch (Exception e)
							{
								continue;
							}

							// filter the data based on the min,max values
							if (minValue <= value && value <= maxValue){
								numericData.add(value);
								recordData[rowIndex][colIndex] = value;
							}								
							else
								continue;
						}
						else
						{
							dataObj = result.rows[i][1];
							if (dataObj == null)
								continue;
							
							stringData.add(dataObj.toString());
							recordData[rowIndex][colIndex] =  dataObj;
						}
						if (hasSecondaryKey)
							hasSecondaryKey = getSecKeys(result, secKeys, i);
					}
				}
			}
			catch (SQLException e)
			{
				e.printStackTrace();
				
			}
			catch (NullPointerException e)
			{
				e.printStackTrace();
				throw(new RemoteException(e.getMessage()));
			}
			
		}
		
		WeaveRecordList result = new WeaveRecordList();
		result.recordData = recordData;
		result.keyType = keyType;
		result.recordKeys = keysArray;
		result.attributeColumnMetadata = metadataList;
		
		return result;
	}	
	
	/**
	 * should return two columns -- keys and data
	 */
	public AttributeColumnDataWithKeys getAttributeColumn(Map<String, String> params)
		throws RemoteException
	{
		String dataTableName = params.get(PublicMetadata.DATATABLE);
		String attributeColumnName = params.get(PublicMetadata.NAME);

		// remove min,max,sqlParams -- do not use them to query the config
		String paramMinStr = params.remove(PublicMetadata.MIN);
		String paramMaxStr = params.remove(PublicMetadata.MAX);
		String sqlParams = params.remove(PrivateMetadata.SQLPARAMS);

		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		
                AttributeColumnInfo tmpinfo = new AttributeColumnInfo();
                tmpinfo.publicMetadata = params;
		List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(tmpinfo);
		
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		String debug = "";
		for (Entry<String,String> e : params.entrySet())
			debug += "; " + e;
		if (infoList.size() > 1)
			throw new RemoteException("More than one matching column found. "+params+debug);
		
		AttributeColumnInfo info = infoList.get(0);
		String dataWithKeysQuery = info.privateMetadata.get(PrivateMetadata.SQLQUERY);

		if (dataWithKeysQuery.length() == 0)
			throw new RemoteException(String.format("No SQL query is associated with column \"%s\" in dataTable \"%s\"", attributeColumnName, dataTableName));
		
		List<String> keys = new ArrayList<String>();
		List<Double> numericData = null;
		List<String> stringData = null;
		List<String> secKeys = new ArrayList<String>();
		String dataType = info.publicMetadata.get(PublicMetadata.DATATYPE);
		boolean hasSecondaryKey = true;
		
		// use config min,max or param min,max to filter the data
		double minValue = Double.NEGATIVE_INFINITY;
		double maxValue = Double.POSITIVE_INFINITY;
		// first try parsing config min,max values
		try {
			minValue = Double.parseDouble(info.publicMetadata.get(PublicMetadata.MIN));
		} catch (Exception e) { }
		try {
			maxValue = Double.parseDouble(info.publicMetadata.get(PublicMetadata.MAX));
		} catch (Exception e) { }
		// override config min,max with param values if given
		try {
			minValue = Double.parseDouble(paramMinStr);
			// if paramMinStr parses successfully, overwrite returned min metadata
			info.publicMetadata.put(PublicMetadata.MIN, paramMinStr); // this happens only if parseDouble() succeeds
		} catch (Exception e) { }
		try {
			maxValue = Double.parseDouble(paramMaxStr);
			// if paramMaxStr parses successfully, overwrite returned max metadata
			info.publicMetadata.put(PublicMetadata.MAX, paramMaxStr); // this happens only if parseDouble() succeeds
		} catch (Exception e) { }
		
		try
		{
			String connectionName = info.privateMetadata.get(PrivateMetadata.CONNECTION);
			SQLResult result;
			// use default sqlParams if not specified by query params
			if (sqlParams == null || sqlParams.length() == 0)
				sqlParams = info.privateMetadata.get(PrivateMetadata.SQLPARAMS);
			
			if (sqlParams != null && sqlParams.length() > 0)
			{
				String[] args = CSVParser.defaultParser.parseCSV(sqlParams)[0];
				result = SQLUtils.getRowSetFromQuery(config.getNamedConnection(connectionName, true), dataWithKeysQuery, args);
			}
			else
			{
				result = SQLUtils.getRowSetFromQuery(config.getNamedConnection(connectionName, true), dataWithKeysQuery);
			}
			// if dataType is defined in the config file, use that value.
			// otherwise, derive it from the sql result.
			if (dataType.length() == 0)
			{
				dataType = DataType.fromSQLType(result.columnTypes[1]);
				info.publicMetadata.put(PublicMetadata.DATATYPE, dataType); // fill in missing metadata for the client
			}
			if (dataType.equalsIgnoreCase(DataType.NUMBER)) // special case: "number" => Double
				numericData = new ArrayList<Double>();
			else // for every other dataType, use String
				stringData = new ArrayList<String>();
			
			Object keyObj, dataObj;
			double value;
			for( int i = 0; i < result.rows.length; i++)
			{
				keyObj = result.rows[i][0];
				if (keyObj == null)
					continue;
				
				dataObj = result.rows[i][1];
				if (dataObj == null)
					continue;
	
				if (numericData != null)
				{
					try
					{
						value = ((Number)dataObj).doubleValue();
					}
					catch (Exception e)
					{
						continue;
					}

					// filter the data based on the min,max values
					if (minValue <= value && value <= maxValue)
						numericData.add(value);
					else
						continue;
				}
				else
				{
					stringData.add(dataObj.toString());
				}
				keys.add(keyObj.toString());
				if (hasSecondaryKey)
					hasSecondaryKey = getSecKeys(result, secKeys, i);
			}
		}
		catch (SQLException e)
		{
			System.out.println(dataWithKeysQuery);
			e.printStackTrace();
			String msg = String.format(
					"Unable to retrieve AttributeColumn \"%s\" in DataTable \"%s\". %s",
					attributeColumnName, dataTableName, e.getMessage()
				);
			throw(new RemoteException(msg));
		}
		catch (NullPointerException e)
		{
			e.printStackTrace();
			throw(new RemoteException(e.getMessage()));
		}

		AttributeColumnDataWithKeys result = new AttributeColumnDataWithKeys(
				info.publicMetadata,
				keys.toArray(new String[0]),
				numericData != null ? numericData.toArray(new Double[0]) : stringData.toArray(new String[0]),
				hasSecondaryKey ? secKeys.toArray(new String[0]) : null
			);
		
		return result;
	}
	
	private boolean getSecKeys(SQLResult rowset, List<String> secKeys, int rownum)
	{
		try
		{
			Object secKeyValueObject = rowset.rows[rownum][2];
			if (! secKeyValueObject.equals(null))
				secKeys.add(secKeyValueObject.toString());	
		}
		catch (Exception e)
		{
			return false;
		}
		return true;
	}
	
	public SQLResult getRowSetFromAttributeColumn(Map<String, String> params)
		throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
                AttributeColumnInfo tmpinfo = new AttributeColumnInfo();
                tmpinfo.publicMetadata = params;
		List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(tmpinfo);
		if (infoList.size() < 1)
			throw new RemoteException("No matching column found. "+params);
		if (infoList.size() > 1)
			throw new RemoteException("More than one matching column found. "+params);
		
		AttributeColumnInfo info = infoList.get(0);
		try
		{
			String connectionName = info.privateMetadata.get(PrivateMetadata.CONNECTION);
			String query = info.privateMetadata.get(PrivateMetadata.SQLQUERY);
			SQLResult result = SQLUtils.getRowSetFromQuery(config.getNamedConnection(connectionName, true), query);
			return result;
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
	}
	
	public GeometryStreamMetadata getGeometryStreamTileDescriptors(String geometryCollectionName)
		throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
		Map<String,String> publicMetadataFilter = new HashMap<String,String>();
		publicMetadataFilter.put(PublicMetadata.NAME, geometryCollectionName);
                AttributeColumnInfo tmpinfo = new AttributeColumnInfo();
                tmpinfo.publicMetadata = publicMetadataFilter;
		List<AttributeColumnInfo> infoList = config.findAttributeColumnInfo(tmpinfo);
		if (infoList.size() == 1)
			return getGeometryStreamTileDescriptors(infoList.get(0).id);
		throw new RemoteException(String.format("%s matches for geometry collection \"%s\"", infoList.size(), geometryCollectionName));
	}
	public GeometryStreamMetadata getGeometryStreamTileDescriptors(int id)
		throws RemoteException
	{
		configManager.detectConfigChanges();
		ISQLConfig config = configManager.getConfig();
	
		AttributeColumnInfo info = config.getAttributeColumnInfo(id);
		if (info == null)
			throw new RemoteException(String.format("Geometry collection with id \"%s\" does not exist.", id));
		
		String schema = info.privateMetadata.get(PrivateMetadata.SCHEMA);
		String tablePrefix = info.privateMetadata.get(PrivateMetadata.TABLEPREFIX);
		GeometryStreamMetadata result = new GeometryStreamMetadata();
		result.setId(id);
		result.setMetadata(info.publicMetadata);
		try {
			Connection conn = config.getNamedConnection(info.privateMetadata.get(PrivateMetadata.CONNECTION), true);
	
			// get tile descriptors
			result.setMetadataTileDescriptors(
					SQLGeometryStreamReader.getMetadataTileDescriptors(conn, schema, tablePrefix)
				);
			result.setGeometryTileDescriptors(
					SQLGeometryStreamReader.getGeometryTileDescriptors(conn, schema, tablePrefix)
				);
		}
		catch (SQLException e)
		{
			System.out.println(String.format("getGeometryStreamTileDescriptors(%s): schema=\"%s\" tablePrefix=\"%s\"", id, schema, tablePrefix));
			e.printStackTrace();
			throw new RemoteException("Failed to retrieve GeometryStreamMetadata for GeometryCollection \""+id+"\"", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage());
		}
		
		// return tile descriptors
		return result;
	}
	
	public byte[] getGeometryStreamMetadataTiles(int geometryColumnId, List<Integer> tileIDs)
		throws RemoteException
	{
		ISQLConfig config = configManager.getConfig();
		AttributeColumnInfo info = config.getAttributeColumnInfo(geometryColumnId);
		if (info == null)
			throw new RemoteException(String.format("Geometry collection \"%s\" does not exist.", geometryColumnId));
	
		// get stream from sql table
		byte[] result;
		try
		{
			Connection conn = config.getNamedConnection(info.privateMetadata.get(PrivateMetadata.CONNECTION), true);
			String schema = info.privateMetadata.get(PrivateMetadata.SCHEMA);
			String tablePrefix = info.privateMetadata.get(PrivateMetadata.TABLEPREFIX);
			result = SQLGeometryStreamReader.getMetadataTiles(conn, schema, tablePrefix, tileIDs);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException("Unable to retrieve metadata tiles for geometry collection \""+geometryColumnId+"\"", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage(), e);
		}
	
		// return stream
		return result;
	}
	
	public byte[] getGeometryStreamGeometryTiles(int geometryColumnId, List<Integer> tileIDs)
		throws RemoteException
	{
		ISQLConfig config = configManager.getConfig();
		AttributeColumnInfo info = config.getAttributeColumnInfo(geometryColumnId);
		if (info == null)
			throw new RemoteException(String.format("Geometry collection \"%s\" does not exist.", geometryColumnId));
	
		// get stream from sql table
		byte[] result;
		try
		{
			Connection conn = config.getNamedConnection(info.privateMetadata.get(PrivateMetadata.CONNECTION), true);
			String schema = info.privateMetadata.get(PrivateMetadata.SCHEMA);
			String tablePrefix = info.privateMetadata.get(PrivateMetadata.TABLEPREFIX);
			result = SQLGeometryStreamReader.getGeometryTiles(conn, schema, tablePrefix, tileIDs);
		}
		catch (SQLException e)
		{
			e.printStackTrace();
			throw new RemoteException("Unable to retrieve geometry tiles for geometry collection \""+geometryColumnId+"\"", e);
		}
		catch (IOException e)
		{
			e.printStackTrace();
			throw new RemoteException(e.getMessage(), e);
		}
	
		// return stream
		return result;
	}
	
	
	
	

	/**
	 * createReport - sends a request to the webservices to create a report
	 * @param reportType - must match an item in the ReportFactory.ReportType enum 
	 *                     e.g. "CATEGORYREPORT" or "COMPAREREPORT"
	 * @param keys subset of keys to include in the report
	 * @return ((success or fail string) + (report name))
	 * @throws Exception 
	 */
	
	public String createReport(String reportDefinitionFileName, List<String> keys) throws Exception
	{
		WeaveReport rpt = new WeaveReport(configManager.getContextParams().getDocrootPath());
		String result = rpt.createReport(configManager.getConfig(), this, reportDefinitionFileName, keys);
		return result;
	}
}
