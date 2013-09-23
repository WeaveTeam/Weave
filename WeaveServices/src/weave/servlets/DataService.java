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

import static weave.config.WeaveConfig.getConnectionConfig;
import static weave.config.WeaveConfig.getDataConfig;
import static weave.config.WeaveConfig.initWeaveConfig;

import java.rmi.RemoteException;
import java.security.InvalidParameterException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.Vector;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.postgis.Geometry;
import org.postgis.PGgeometry;
import org.postgis.Point;

import weave.beans.AttributeColumnData;
import weave.beans.GeometryStreamMetadata;
import weave.beans.PGGeom;
import weave.beans.WeaveJsonDataSet;
import weave.beans.WeaveRecordList;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.DataConfig;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityWithChildren;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.EntityHierarchyInfo;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;
import weave.config.WeaveContextParams;
import weave.geometrystream.SQLGeometryStreamReader;
import weave.utils.CSVParser;
import weave.utils.ListUtils;
import weave.utils.MapUtils;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;
import weave.utils.SQLUtils.WhereClause.ColumnFilter;
import weave.utils.Strings;
/**
 * This class connects to a database and gets data
 * uses xml configuration file to get connection/query info
 * 
 * @author Andy Dufilie
 */
public class DataService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public DataService()
	{
	}
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
	}
	
	@SuppressWarnings("rawtypes")
	@Override
	protected Object cast(Object value, Class<?> type)
	{
		if (type == FilteredColumnRequest.class && value != null && value instanceof Map)
		{
			FilteredColumnRequest fcr = new FilteredColumnRequest();
			fcr.id = (Integer)cast(MapUtils.getValue((Map)value, "id", -1), int.class);
			fcr.filters = (Object[])cast(MapUtils.getValue((Map)value, "filters", null), Object[].class);
			if (fcr.filters != null)
				for (int i = 0; i < fcr.filters.length; i++)
				{
					Object item = fcr.filters[i];
					if (item != null && item.getClass() == ArrayList.class)
						fcr.filters[i] = cast(item, Object[].class);
				}
			return fcr;
		}
		if (type == FilteredColumnRequest[].class && value != null && value.getClass() == Object[].class)
		{
			Object[] input = (Object[]) value;
			FilteredColumnRequest[] output = new FilteredColumnRequest[input.length];
			for (int i = 0; i < input.length; i++)
			{
				output[i] = (FilteredColumnRequest)cast(input[i], FilteredColumnRequest.class);
			}
			value = output;
		}
		if (type == DataEntityMetadata.class && value != null && value instanceof Map)
		{
			return DataEntityMetadata.fromMap((Map)value);
		}
		return super.cast(value, type);
	}
	
	/////////////////////
	// helper functions
	
	private DataEntity getColumnEntity(int columnId) throws RemoteException
	{
		DataEntity entity = getDataConfig().getEntity(columnId);
		if (entity == null || entity.type != DataEntity.TYPE_COLUMN)
			throw new RemoteException("No column with id " + columnId);
		return entity;
	}
	
	private static boolean isEmpty(String str)
	{
		return str == null || str.length() == 0;
	}
	
	private void assertColumnHasPrivateMetadata(DataEntity columnEntity, String ... fields) throws RemoteException
	{
		for (String field : fields)
		{
			if (isEmpty(columnEntity.privateMetadata.get(field)))
			{
				String dataType = columnEntity.publicMetadata.get(PublicMetadata.DATATYPE);
				String description = (dataType != null && dataType.equals(DataType.GEOMETRY)) ? "Geometry column" : "Column";
				throw new RemoteException(String.format("%s %s is missing private metadata %s", description, columnEntity.id, field));
			}
		}
	}
	
	private boolean assertStreamingGeometryColumn(DataEntity entity, boolean throwException) throws RemoteException
	{
		try
		{
			String dataType = entity.publicMetadata.get(PublicMetadata.DATATYPE);
			if (dataType == null || !dataType.equals(DataType.GEOMETRY))
				throw new RemoteException(String.format("Column %s dataType is %s, not %s", entity.id, dataType, DataType.GEOMETRY));
			assertColumnHasPrivateMetadata(entity, PrivateMetadata.CONNECTION, PrivateMetadata.SQLSCHEMA, PrivateMetadata.SQLTABLEPREFIX);
			return true;
		}
		catch (RemoteException e)
		{
			if (throwException)
				throw e;
			return false;
		}
	}
	
	////////////////////
	// DataEntity info
	
	public EntityHierarchyInfo[] getDataTableList() throws RemoteException
	{
		return getDataConfig().getEntityHierarchyInfo(DataEntity.TYPE_DATATABLE);
	}

	public int[] getEntityChildIds(int parentId) throws RemoteException
	{
		return ListUtils.toIntArray( getDataConfig().getChildIds(parentId) );
	}

	public int[] getEntityIdsByMetadata(Map<String,String> publicMetadata, int entityType) throws RemoteException
	{
		DataEntityMetadata dem = new DataEntityMetadata();
		dem.publicMetadata = publicMetadata;
		int[] ids = ListUtils.toIntArray( getDataConfig().getEntityIdsByMetadata(dem, entityType) );
		Arrays.sort(ids);
		return ids;
	}

	public DataEntity[] getEntitiesById(int[] ids) throws RemoteException
	{
		DataConfig config = getDataConfig();
		Set<Integer> idSet = new HashSet<Integer>();
		for (int id : ids)
			idSet.add(id);
		DataEntity[] result = config.getEntitiesById(idSet).toArray(new DataEntity[0]);
		for (int i = 0; i < result.length; i++)
		{
			int[] childIds = ListUtils.toIntArray( config.getChildIds(result[i].id) );
			result[i] = new DataEntityWithChildren(result[i], childIds);
			
			// prevent user from receiving private metadata
			result[i].privateMetadata = null;
		}
		return result;
	}
	
	public int[] getParents(int childId) throws RemoteException
	{
		int[] ids = ListUtils.toIntArray( getDataConfig().getParentIds(Arrays.asList(childId)) );
		Arrays.sort(ids);
		return ids;
	}
	
	////////////
	// Columns
	
	private static ConnectionInfo getColumnConnectionInfo(DataEntity entity) throws RemoteException
	{
		String connName = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
		ConnectionInfo connInfo = getConnectionConfig().getConnectionInfo(connName);
 		if (connInfo == null)
		{
			String title = entity.publicMetadata.get(PublicMetadata.TITLE);
			throw new RemoteException(String.format("Connection named '%s' associated with column #%s (%s) no longer exists", connName, entity.id, title));
		}
 		return connInfo;
	}
	
	public AttributeColumnData getColumn(int columnId, double minParam, double maxParam, String[] sqlParams)
		throws RemoteException
	{
		DataEntity entity = getColumnEntity(columnId);
		
		// if it's a geometry column, just return the metadata
		if (assertStreamingGeometryColumn(entity, false))
		{
			GeometryStreamMetadata gsm = (GeometryStreamMetadata) getGeometryData(entity, GeomStreamComponent.TILE_DESCRIPTORS, null);
			AttributeColumnData result = new AttributeColumnData();
			result.id = columnId;
			result.metadata = entity.publicMetadata;
			result.metadataTileDescriptors = gsm.metadataTileDescriptors;
			result.geometryTileDescriptors = gsm.geometryTileDescriptors;
			return result;
		}
		
		String query = entity.privateMetadata.get(PrivateMetadata.SQLQUERY);
		String dataType = entity.publicMetadata.get(PublicMetadata.DATATYPE);
		
		ConnectionInfo connInfo = getColumnConnectionInfo(entity);
		
		List<String> keys = new ArrayList<String>();
		List<Double> numericData = null;
		List<String> stringData = null;
		List<Object> thirdColumn = null; // hack for dimension slider format
		List<PGGeom> geometricData = null;
		
		// use config min,max or param min,max to filter the data
		double minValue = Double.NaN;
		double maxValue = Double.NaN;
		
		// override config min,max with param values if given
		if (!Double.isNaN(minParam))
		{
			minValue = minParam;
		}
		else
		{
			try {
				minValue = Double.parseDouble(entity.publicMetadata.get(PublicMetadata.MIN));
			} catch (Exception e) { }
		}
		if (!Double.isNaN(maxParam))
		{
			maxValue = maxParam;
		}
		else
		{
			try {
				maxValue = Double.parseDouble(entity.publicMetadata.get(PublicMetadata.MAX));
			} catch (Exception e) { }
		}
		
		if (Double.isNaN(minValue))
			minValue = Double.NEGATIVE_INFINITY;
		
		if (Double.isNaN(maxValue))
			maxValue = Double.POSITIVE_INFINITY;
		
		try
		{
			Connection conn = connInfo.getStaticReadOnlyConnection();
			
			// use default sqlParams if not specified by query params
			if (sqlParams == null || sqlParams.length == 0)
			{
				String sqlParamsString = entity.privateMetadata.get(PrivateMetadata.SQLPARAMS);
				sqlParams = CSVParser.defaultParser.parseCSVRow(sqlParamsString, true);
			}
			
			SQLResult result = SQLUtils.getResultFromQuery(conn, query, sqlParams, false);
			
			// if dataType is defined in the config file, use that value.
			// otherwise, derive it from the sql result.
			if (isEmpty(dataType))
			{
				dataType = DataType.fromSQLType(result.columnTypes[1]);
				entity.publicMetadata.put(PublicMetadata.DATATYPE, dataType); // fill in missing metadata for the client
			}
			if (dataType.equalsIgnoreCase(DataType.NUMBER)) // special case: "number" => Double
			{
				numericData = new LinkedList<Double>();
			}
			else if (dataType.equalsIgnoreCase(DataType.GEOMETRY))
			{
				geometricData = new LinkedList<PGGeom>();
			}
			else
			{
				stringData = new LinkedList<String>();
			}
			
			// hack for dimension slider format
			if (result.columnTypes.length == 3)
				thirdColumn = new LinkedList<Object>();
			
			Object keyObj, dataObj;
			double value;
			for (int i = 0; i < result.rows.length; i++)
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
						if (dataObj instanceof String)
							dataObj = Double.parseDouble((String)dataObj);
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
				else if (geometricData != null)
				{
					// The dataObj must be cast to PGgeometry before an individual Geometry can be extracted.
					if (!(dataObj instanceof PGgeometry))
						continue;
					Geometry geom = ((PGgeometry) dataObj).getGeometry();
					int numPoints = geom.numPoints();
					// Create PGGeom Bean here and fill it up!
					PGGeom bean = new PGGeom();
					bean.type = geom.getType();
					bean.xyCoords = new double[numPoints * 2];
					for (int j = 0; j < numPoints; j++)
					{
						Point pt = geom.getPoint(j);
						bean.xyCoords[j * 2] = pt.x;
						bean.xyCoords[j * 2 + 1] = pt.y;
					}
					geometricData.add(bean);
				}
				else
				{
					stringData.add(dataObj.toString());
				}
				
				// if we got here, it means a data value was added, so add the corresponding key
				keys.add(keyObj.toString());
				
				// hack for dimension slider format
				if (thirdColumn != null)
					thirdColumn.add(result.rows[i][2]);
			}
		}
		catch (SQLException e)
		{
			System.err.println(query);
			e.printStackTrace();
			throw new RemoteException(String.format("Unable to retrieve data for column %s", columnId));
		}
		catch (NullPointerException e)
		{
			e.printStackTrace();
			throw(new RemoteException(e.getMessage()));
		}

		AttributeColumnData result = new AttributeColumnData();
		result.id = columnId;
		result.metadata = entity.publicMetadata;
		result.keys = keys.toArray(new String[keys.size()]);
		if (numericData != null)
			result.data = numericData.toArray();
		else if (geometricData != null)
			result.data = geometricData.toArray();
		else
			result.data = stringData.toArray();
		// hack for dimension slider
		if (thirdColumn != null)
			result.thirdColumn = thirdColumn.toArray();
		
		return result;
	}
	
	/**
	 * This function is intended for use with JsonRPC calls.
	 * @param columnIds A list of column IDs.
	 * @return A WeaveJsonDataSet containing all the data from the columns.
	 * @throws RemoteException
	 */
	public WeaveJsonDataSet getDataSet(int[] columnIds) throws RemoteException
	{
		WeaveJsonDataSet result = new WeaveJsonDataSet();
		for (Integer columnId : columnIds)
		{
			try
			{
				AttributeColumnData columnData = getColumn(columnId, Double.NaN, Double.NaN, null);
				result.addColumnData(columnData);
			}
			catch (RemoteException e)
			{
				e.printStackTrace();
			}
		}
		return result;
	}
	
	/////////////////////
	// geometry columns
	
	public byte[] getGeometryStreamMetadataTiles(int columnId, int[] tileIDs) throws RemoteException
	{
		DataEntity entity = getColumnEntity(columnId);
		return (byte[]) getGeometryData(entity, GeomStreamComponent.METADATA_TILES, tileIDs);
	}
	
	public byte[] getGeometryStreamGeometryTiles(int columnId, int[] tileIDs) throws RemoteException
	{
		DataEntity entity = getColumnEntity(columnId);
		return (byte[]) getGeometryData(entity, GeomStreamComponent.GEOMETRY_TILES, tileIDs);
	}
	
	private static enum GeomStreamComponent { TILE_DESCRIPTORS, METADATA_TILES, GEOMETRY_TILES };
	
	private Object getGeometryData(DataEntity entity, GeomStreamComponent component, int[] tileIDs) throws RemoteException
	{
		assertStreamingGeometryColumn(entity, true);
		
		Connection conn = getColumnConnectionInfo(entity).getStaticReadOnlyConnection();
		String schema = entity.privateMetadata.get(PrivateMetadata.SQLSCHEMA);
		String tablePrefix = entity.privateMetadata.get(PrivateMetadata.SQLTABLEPREFIX);
		try
		{
			switch (component)
			{
				case TILE_DESCRIPTORS:
					GeometryStreamMetadata result = new GeometryStreamMetadata();
					result.metadataTileDescriptors = SQLGeometryStreamReader.getMetadataTileDescriptors(conn, schema, tablePrefix);
					result.geometryTileDescriptors = SQLGeometryStreamReader.getGeometryTileDescriptors(conn, schema, tablePrefix);
					return result;
					
				case METADATA_TILES:
					return SQLGeometryStreamReader.getMetadataTiles(conn, schema, tablePrefix, tileIDs);
					
				case GEOMETRY_TILES:
					return SQLGeometryStreamReader.getGeometryTiles(conn, schema, tablePrefix, tileIDs);
					
				default:
					throw new InvalidParameterException("Invalid GeometryStreamComponent param.");
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
			throw new RemoteException(String.format("Unable to read geometry data (id=%s)", entity.id));
		}
	}
	
	////////////////////////////
	// Row query
	
	public WeaveRecordList getRows(String keyType, String[] keysArray) throws RemoteException
	{
		DataConfig dataConfig = getDataConfig();
		
		DataEntityMetadata params = new DataEntityMetadata();
		params.publicMetadata.put(PublicMetadata.KEYTYPE,keyType);
		List<Integer> columnIds = new ArrayList<Integer>( dataConfig.getEntityIdsByMetadata(params, DataEntity.TYPE_COLUMN) );

		if (columnIds.size() > 100)
			columnIds = columnIds.subList(0, 100);

		FilteredColumnRequest[] requestedColumns = new FilteredColumnRequest[columnIds.size()];
		for (int i = 0; i < requestedColumns.length; i++)
		{
			FilteredColumnRequest fcr = new FilteredColumnRequest();
			fcr.id = columnIds.get(i);
			requestedColumns[i] = fcr;
		}
		return DataService.getFilteredRows(requestedColumns, keysArray);
	}
	
	public static class FilteredColumnRequest
	{
		public int id;
		
		/**
		 * Either [[min,max],[min2,max2],...] for numeric values or ["a","b",...] for string values.
		 */
		public Object[] filters;
	}
	
//	public WeaveRecordList getFilteredData(FilteredColumnRequest[] columns) throws RemoteException
//	{
//		return getFilteredRows(columns, null);
//	}
	
	/*
	
	[
		{id: 1, filters: ["a","b"]},
		{id: 2, filters: [[min,max],[min2,max2]]}
	]
	
	 */

	private static SQLResult getFilteredRowsFromSQL(Connection conn, String schema, String table, FilteredColumnRequest[] columns, DataEntity[] entities) throws SQLException
	{
		ColumnFilter[] cfArray = new ColumnFilter[columns.length];
		String[] quotedFields = new String[columns.length];
		for (int i = 0; i < columns.length; i++)
		{
			cfArray[i] = new ColumnFilter();
			cfArray[i].field = entities[i].privateMetadata.get(PrivateMetadata.SQLCOLUMN);
			cfArray[i].filters = columns[i].filters;
			quotedFields[i] = SQLUtils.quoteSymbol(conn, cfArray[i].field);
		}
		
		WhereClause<Object> where = WhereClause.fromFilters(conn, cfArray);

		String query = String.format(
			"SELECT %s FROM %s %s",
			Strings.join(",", quotedFields),
			SQLUtils.quoteSchemaTable(conn, schema, table),
			where.clause
		);
		
		return SQLUtils.getResultFromQuery(conn, query, where.params.toArray(), false);
	}
	
	@SuppressWarnings("unchecked")
	public static WeaveRecordList getFilteredRows(FilteredColumnRequest[] columns, String[] keysArray) throws RemoteException
	{
		List<Integer> columnIds = new Vector<Integer>();
		for (FilteredColumnRequest fcr : columns)
			columnIds.add(fcr.id);
		
		DataConfig dataConfig = getDataConfig();
		DataEntity[] entities;
		Map<String,String>[] metadataList;
		{
			Collection<DataEntity> unordered = dataConfig.getEntitiesById(columnIds);
			Map<Integer, DataEntity> lookup = new HashMap<Integer, DataEntity>();
			for (DataEntity de : unordered)
				lookup.put(de.id, de);
			
			int n = columnIds.size();
			entities = new DataEntity[n];
			metadataList = new Map[n];
			for (int i = 0; i < n; i++)
			{
				entities[i] = lookup.get(columnIds.get(i));
				metadataList[i] = entities[i].publicMetadata;
			}
		}
		
		if (entities.length < 1)
			throw new RemoteException("No columns found matching specified ids: "+columnIds);
		
		String keyType = entities[0].publicMetadata.get(PublicMetadata.KEYTYPE);
		for (DataEntity entity : entities)
		{
			String keyType2 = entity.publicMetadata.get(PublicMetadata.KEYTYPE);
			if (keyType != keyType2 && (keyType == null || keyType2 == null || !keyType.equals(keyType2)))
				throw new RemoteException("Specified columns must all have same keyType.");
		}

		WeaveRecordList result = new WeaveRecordList();

		if (keysArray == null)
		{
			boolean canGenerateSQL = true;
			// check to see if all the columns are from the same SQL table.
			String connection = null;
			String sqlSchema = null;
			String sqlTable = null;
			for (DataEntity entity : entities)
			{
				String c = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
				String s = entity.privateMetadata.get(PrivateMetadata.SQLSCHEMA);
				String t = entity.privateMetadata.get(PrivateMetadata.SQLTABLE);
				if (connection == null)
					connection = c;
				if (sqlSchema == null)
					sqlSchema = s;
				if (sqlTable == null)
					sqlTable = t;
				
				if (!Strings.equal(connection, c) || !Strings.equal(sqlSchema, s) || !Strings.equal(sqlTable, t))
				{
					canGenerateSQL = false;
					break;
				}
			}
			if (canGenerateSQL)
			{
				Connection conn = getColumnConnectionInfo(entities[0]).getStaticReadOnlyConnection();
				try
				{
					result.recordData = getFilteredRowsFromSQL(conn, sqlSchema, sqlTable, columns, entities).rows;
				}
				catch (SQLException e)
				{
					throw new RemoteException("getFilteredRows() failed.", e);
				}
			}
		}
		
		if (result.recordData == null)
		{
			HashMap<String,Object[]> data = new HashMap<String,Object[]>();
			if (keysArray != null)
				for (String key : keysArray)
					data.put(key, new Object[entities.length]);
			
			for (int colIndex = 0; colIndex < entities.length; colIndex++)
			{
				Object[] filters = columns[colIndex].filters;
				DataEntity info = entities[colIndex];
				String sqlQuery = info.privateMetadata.get(PrivateMetadata.SQLQUERY);
				String sqlParams = info.privateMetadata.get(PrivateMetadata.SQLPARAMS);
				
				//if (dataWithKeysQuery.length() == 0)
				//	throw new RemoteException(String.format("No SQL query is associated with column \"%s\" in dataTable \"%s\"", attributeColumnName, dataTableName));
				
				String dataType = info.publicMetadata.get(PublicMetadata.DATATYPE);
				
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
				 * columnInfoArray = config.getDataEntity(params);
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
					boolean errorReported = false;
					
					Connection conn = getColumnConnectionInfo(info).getStaticReadOnlyConnection();
					String[] sqlParamsArray = null;
					if (sqlParams != null && sqlParams.length() > 0)
						sqlParamsArray = CSVParser.defaultParser.parseCSV(sqlParams, true)[0];
					
					SQLResult sqlResult = SQLUtils.getResultFromQuery(conn, sqlQuery, sqlParamsArray, false);
					
					//timer.lap("get row set");
					// if dataType is defined in the config file, use that value.
					// otherwise, derive it from the sql result.
					if (isEmpty(dataType))
						dataType = DataType.fromSQLType(sqlResult.columnTypes[1]);
					boolean isNumeric = dataType != null && dataType.equalsIgnoreCase(DataType.NUMBER);
					
					Object keyObj, dataObj;
					for (int iRow = 0; iRow < sqlResult.rows.length; iRow++)
					{
						keyObj = sqlResult.rows[iRow][0];
						dataObj = sqlResult.rows[iRow][1];
						
						if (keyObj == null || dataObj == null)
							continue;
						keyObj = keyObj.toString();
						
						if (data.containsKey(keyObj))
						{
							// if row has been set to null, skip
							if (data.get(keyObj) == null)
								continue;
						}
						else
						{
							// if keys are specified and row is not present, skip
							if (keysArray != null)
								continue;
						}
						
						try
						{
							boolean passedFilters = true;
							
							// convert the data to the appropriate type, then filter by value
							if (isNumeric)
							{
								if (dataObj instanceof Number) // TEMPORARY SOLUTION - FIX ME
								{
									double doubleValue = ((Number)dataObj).doubleValue();
									// filter the data based on the min,max values
									if (minValue <= doubleValue && doubleValue <= maxValue)
									{
										// filter the value
										if (filters != null)
										{
											passedFilters = false;
											for (Object range : filters)
											{
												Number min = (Number)((Object[])range)[0];
												Number max = (Number)((Object[])range)[1];
												if (min.doubleValue() <= doubleValue && doubleValue <= max.doubleValue())
												{
													passedFilters = true;
													break;
												}
											}
										}
									}
									else
										passedFilters = false;
								}
								else
									passedFilters = false;
							}
							else
							{
								String stringValue = dataObj.toString();
								dataObj = stringValue;
								// filter the value
								if (filters != null)
								{
									passedFilters = false;
									for (Object filter : filters)
									{
										if (filter.equals(stringValue))
										{
											passedFilters = true;
											break;
										}
									}
								}
							}
							
							Object[] row = data.get(keyObj);
							
							if (passedFilters)
							{
								// add existing row if it has not been added yet
								if (!data.containsKey(keyObj))
								{
									for (int i = 0; i < colIndex; i++)
									{
										Object[] prevFilters = columns[i].filters;
										if (prevFilters != null)
										{
											passedFilters = false;
											break;
										}
									}
									if (passedFilters)
										row = new Object[entities.length];
									
									data.put((String)keyObj, row);
								}
								
								if (row != null)
									row[colIndex] = dataObj;
							}
							else
							{
								// remove existing row if value did not pass filters
								if (row != null || !data.containsKey(keyObj))
									data.put((String)keyObj, null);
							}
						}
						catch (Exception e)
						{
							if (!errorReported)
							{
								errorReported = true;
								e.printStackTrace();
							}
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
					throw new RemoteException(e.getMessage());
				}
			}
			
			if (keysArray == null)
			{
				LinkedList<String> keys = new LinkedList<String>();
				for (Entry<String,Object[]> entry : data.entrySet())
					if (entry.getValue() != null)
						keys.add(entry.getKey());
				keysArray = keys.toArray(new String[keys.size()]);
			}
			
			Object[][] rows = new Object[keysArray.length][];
			for (int iKey = 0; iKey < keysArray.length; iKey++)
				rows[iKey] = data.get(keysArray[iKey]);
			
			result.recordData = rows;
		}
		
		result.keyType = keyType;
		result.recordKeys = keysArray;
		result.attributeColumnMetadata = metadataList;
		
		return result;
	}

	/////////////////////////////
	// backwards compatibility
	
	/**
	 * @param metadata The metadata query.
	 * @return The id of the matching column.
	 * @throws RemoteException Thrown if the metadata query does not match exactly one column.
	 */
	@Deprecated
	public AttributeColumnData getColumnFromMetadata(Map<String, String> metadata)
		throws RemoteException
	{
		if (metadata == null || metadata.size() == 0)
			throw new RemoteException("No metadata query parameters specified.");
		
		DataEntityMetadata query = new DataEntityMetadata();
		query.publicMetadata = metadata;
		
		final String DATATABLE = "dataTable";
		final String NAME = "name";
		
		// exclude these parameters from the query
		if (metadata.containsKey(NAME))
			metadata.remove(PublicMetadata.TITLE);
		String minStr = metadata.remove(PublicMetadata.MIN);
		String maxStr = metadata.remove(PublicMetadata.MAX);
		String paramsStr = metadata.remove(PrivateMetadata.SQLPARAMS);
		
		DataConfig dataConfig = getDataConfig();
		
		Collection<Integer> ids = dataConfig.getEntityIdsByMetadata(query, DataEntity.TYPE_COLUMN);
		
		// attempt recovery for backwards compatibility
		if (ids.size() == 0)
		{
			String dataType = metadata.get(PublicMetadata.DATATYPE);
			if (metadata.containsKey(DATATABLE) && metadata.containsKey(NAME))
			{
				// try to find columns sqlTable==dataTable and sqlColumn=name
				DataEntityMetadata sqlInfoQuery = new DataEntityMetadata();
				String sqlTable = metadata.get(DATATABLE);
				String sqlColumn = metadata.get(NAME);
				for (int i = 0; i < 2; i++)
				{
					if (i == 1)
						sqlTable = sqlTable.toLowerCase();
					sqlInfoQuery.setPrivateMetadata(
						PrivateMetadata.SQLTABLE, sqlTable,
						PrivateMetadata.SQLCOLUMN, sqlColumn
					);
					ids = dataConfig.getEntityIdsByMetadata(sqlInfoQuery, DataEntity.TYPE_COLUMN);
					if (ids.size() > 0)
						break;
				}
			}
			else if (metadata.containsKey(NAME) && dataType != null && dataType.equals(DataType.GEOMETRY))
			{
				metadata.put(PublicMetadata.TITLE, metadata.remove(NAME));
				ids = dataConfig.getEntityIdsByMetadata(query, DataEntity.TYPE_COLUMN);
			}
			if (ids.size() == 0)
				throw new RemoteException("No column matches metadata query: " + metadata);
		}
		
		// warning if more than one column
		if (ids.size() > 1)
		{
			String message = String.format(
					"WARNING: Multiple columns (%s) match metadata query: %s",
					ids.size(),
					metadata
				);
			System.err.println(message);
			//throw new RemoteException(message);
		}
		
		// return first column
		int id = ListUtils.getFirstSortedItem(ids, DataConfig.NULL);
		double min = Double.NaN, max = Double.NaN;
		try { min = (Double)cast(minStr, double.class); } catch (Throwable t) { }
		try { max = (Double)cast(maxStr, double.class); } catch (Throwable t) { }
		String[] sqlParams = CSVParser.defaultParser.parseCSVRow(paramsStr, true);
		return getColumn(id, min, max, sqlParams);
	}
}
