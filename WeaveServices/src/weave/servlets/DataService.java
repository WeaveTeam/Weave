/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

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
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.Set;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpSession;

import org.postgis.Geometry;
import org.postgis.PGgeometry;
import org.postgis.Point;

import weave.beans.AttributeColumnData;
import weave.beans.GeometryStreamMetadata;
import weave.beans.PGGeom;
import weave.beans.TableData;
import weave.beans.WeaveJsonDataSet;
import weave.beans.WeaveRecordList;
import weave.config.ConnectionConfig;
import weave.config.ConnectionConfig.ConnectionInfo;
import weave.config.ConnectionConfig.WeaveAuthenticationException;
import weave.config.DataConfig;
import weave.config.DataConfig.DataEntity;
import weave.config.DataConfig.DataEntityMetadata;
import weave.config.DataConfig.DataEntityWithRelationships;
import weave.config.DataConfig.DataType;
import weave.config.DataConfig.EntityHierarchyInfo;
import weave.config.DataConfig.EntityType;
import weave.config.DataConfig.PrivateMetadata;
import weave.config.DataConfig.PublicMetadata;
import weave.config.WeaveConfig;
import weave.config.WeaveContextParams;
import weave.geometrystream.SQLGeometryStreamReader;
import weave.utils.CSVParser;
import weave.utils.ListUtils;
import weave.utils.MapUtils;
import weave.utils.Numbers;
import weave.utils.SQLResult;
import weave.utils.SQLUtils;
import weave.utils.SQLUtils.WhereClause;
import weave.utils.SQLUtils.WhereClause.ColumnFilter;
import weave.utils.SQLUtils.WhereClause.NestedColumnFilters;
import weave.utils.Strings;

/**
 * This class connects to a database and gets data
 * uses xml configuration file to get connection/query info
 * 
 * @author Andy Dufilie
 */
public class DataService extends WeaveServlet implements IWeaveEntityService
{
	private static final long serialVersionUID = 1L;
	
	public static final int MAX_COLUMN_REQUEST_COUNT = 100;
	
	public DataService()
	{
	}
	
	public void init(ServletConfig config) throws ServletException
	{
		super.init(config);
		initWeaveConfig(WeaveContextParams.getInstance(config.getServletContext()));
	}
	
	public void destroy()
	{
		SQLUtils.staticCleanup();
	}
	
	///////////////////
	// Authentication
	
	private static final String SESSION_USERNAME = "DataService.user";
	private static final String SESSION_PASSWORD = "DataService.pass";
	
	/**
	 * @param user
	 * @param password
	 * @return true if the user has superuser privileges.
	 * @throws RemoteException If authentication fails.
	 */
	public void authenticate(String username, String password) throws RemoteException
	{
		ConnectionConfig connConfig = getConnectionConfig();
		ConnectionInfo info = connConfig.getConnectionInfo(ConnectionInfo.DIRECTORY_SERVICE, username, password);
		if (info == null)
			throw new RemoteException("Incorrect username or password");
		
		HttpSession session = getServletRequestInfo().request.getSession(true);
		session.setAttribute(SESSION_USERNAME, username);
		session.setAttribute(SESSION_PASSWORD, password);
	}
	
	/**
	 * Gets static, read-only connection from a ConnectionInfo object using pass-through authentication if necessary.
	 * @param connInfo
	 * @return
	 * @throws RemoteException
	 */
	private Connection getStaticReadOnlyConnection(ConnectionInfo connInfo) throws RemoteException
	{
 		if (connInfo.requiresAuthentication())
 		{
 			HttpSession session = getServletRequestInfo().request.getSession(true);
 			String user = (String)session.getAttribute(SESSION_USERNAME);
 			String pass = (String)session.getAttribute(SESSION_PASSWORD);
 			connInfo = getConnectionConfig().getConnectionInfo(connInfo.name, user, pass);
 			if (connInfo == null)
 				throw new WeaveAuthenticationException("Incorrect username or password");
 		}
 		return connInfo.getStaticReadOnlyConnection();
	}
	
	/////////////////////
	// helper functions
	
	private DataEntity getColumnEntity(int columnId) throws RemoteException
	{
		DataEntity entity = getDataConfig().getEntity(columnId);
		
		if (entity == null)
			throw new RemoteException("No column with id " + columnId);
		
		String entityType = entity.publicMetadata.get(PublicMetadata.ENTITYTYPE);
		if (!Strings.equal(entityType, EntityType.COLUMN))
			throw new RemoteException(String.format("Entity with id=%s is not a column (entityType: %s)", columnId, entityType));
		
		return entity;
	}
	
	private void assertColumnHasPrivateMetadata(DataEntity columnEntity, String ... fields) throws RemoteException
	{
		for (String field : fields)
		{
			if (Strings.isEmpty(columnEntity.privateMetadata.get(field)))
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
	
	////////////////
	// Server info
	
	public Map<String,Object> getServerInfo() throws RemoteException
	{
		ConnectionConfig connConfig = getConnectionConfig();
		HttpSession session = getServletRequestInfo().request.getSession(true);
		String username = (String)session.getAttribute(SESSION_USERNAME);

		return MapUtils.fromPairs(
			"version", WeaveConfig.getVersion(),
			"authenticatedUser", username,
			"hasDirectoryService", connConfig.getConnectionInfo(ConnectionInfo.DIRECTORY_SERVICE) != null,
			"idFields", connConfig.getDatabaseConfigInfo().idFields
		);
	}
	
	////////////////////
	// DataEntity info
	
	public EntityHierarchyInfo[] getHierarchyInfo(Map<String,String> publicMetadata) throws RemoteException
	{
		return getDataConfig().getEntityHierarchyInfo(publicMetadata);
	}
	
	public DataEntityWithRelationships[] getEntities(int[] ids) throws RemoteException
	{
		if (ids.length > DataConfig.MAX_ENTITY_REQUEST_COUNT)
			throw new RemoteException(String.format("You cannot request more than %s entities at a time.", DataConfig.MAX_ENTITY_REQUEST_COUNT));
		
		// prevent user from receiving private metadata
		return getDataConfig().getEntitiesWithRelationships(ids, false);
	}
	
	public int[] findEntityIds(Map<String,String> publicMetadata, String[] wildcardFields) throws RemoteException
	{
		int[] ids = ListUtils.toIntArray( getDataConfig().searchPublicMetadata(publicMetadata, wildcardFields) );
		Arrays.sort(ids);
		return ids;
	}

	public String[] findPublicFieldValues(String fieldName, String valueSearch) throws RemoteException
	{
		throw new RemoteException("Not implemented yet");
	}

	////////////
	// Columns
	
	private static ConnectionInfo getColumnConnectionInfo(DataEntity entity) throws RemoteException
	{
		String connName = entity.privateMetadata.get(PrivateMetadata.CONNECTION);
		ConnectionConfig connConfig = getConnectionConfig();
		ConnectionInfo connInfo = connConfig.getConnectionInfo(connName);
 		if (connInfo == null)
		{
			String title = entity.publicMetadata.get(PublicMetadata.TITLE);
			throw new RemoteException(String.format("Connection named '%s' associated with column #%s (%s) no longer exists", connName, entity.id, title));
		}
 		return connInfo;
	}
	
	private static class FakeDataProperties
	{
		public int[] dim = new int[]{5};
		public double mean = 0;
		public double stddev = 1;
		public int digits = 2;
		public boolean realKeys = false;
		public int repeat = 1;
		public int sort = 0;
		
		public int getNumRows()
		{
			int numRows = repeat;
			for (int i = 0; i < dim.length; i++)
				numRows *= dim[i];
			return numRows;
		}
		
		public List<String> generateStrings(String prefix)
		{
			int numRows = getNumRows();
			List<String> strings = new ArrayList<String>(numRows);
			generateStrings(strings, 0, prefix, "");
			return strings;
		}
		
		private void generateStrings(List<String> output, int depth, String prefix, String suffix)
		{
			int n = dim[depth];
			for (int i = 1; i <= n; i++)
			{
				String newSuffix = suffix + "_" + i;
				if (depth + 1 < dim.length)
					generateStrings(output, depth + 1, prefix, newSuffix);
				else
					for (int r = 0; r < repeat; r++)
						output.add(prefix + newSuffix);
			}
		}
		
		public List<Double> generateDoubles(long seed)
		{
			int numRows = getNumRows();
			List<Double> doubles = new ArrayList<Double>(numRows);
			Random rand = new Random(seed);
			for (int i = 0; i < numRows; i++)
			{
				Double value = mean + stddev * rand.nextGaussian();
				value = Numbers.roundSignificant(value, digits);
				doubles.add(value);
			}
			if (sort != 0)
				Collections.sort(doubles);
			if (sort < 0)
				Collections.reverse(doubles);
			return doubles;
		}
	}
	
	/**
	 * This retrieves the data and the public metadata for a single attribute column.
	 * @param columnId Either an entity ID (int) or a Map specifying public metadata values that uniquely identify a column. 
	 * @param minParam Used for filtering numeric data
	 * @param maxParam Used for filtering numeric data
	 * @param sqlParams Specifies parameters to be used in place of '?' placeholders that appear in the SQL query for the column.
	 * @return The column data.
	 * @throws RemoteException
	 */
	@SuppressWarnings("unchecked")
	public AttributeColumnData getColumn(Object columnId, double minParam, double maxParam, Object[] sqlParams)
		throws RemoteException
	{
		DataEntity entity = null;
		
		if (columnId instanceof Map)
		{
			@SuppressWarnings("rawtypes")
			Map metadata = (Map)columnId;
			metadata.put(PublicMetadata.ENTITYTYPE, EntityType.COLUMN);
			int[] ids = findEntityIds(metadata, null);
			if (ids.length == 0)
				throw new RemoteException("No column with id " + columnId);
			if (ids.length > 1)
				throw new RemoteException(String.format(
						"The specified metadata does not uniquely identify a column (%s matching columns found): %s",
						ids.length,
						columnId
						));
			entity = getColumnEntity(ids[0]);
		}
		else
		{
			columnId = cast(columnId,  Integer.class);
			entity = getColumnEntity((Integer)columnId);
		}
		
		// if it's a geometry column, just return the metadata
		if (assertStreamingGeometryColumn(entity, false))
		{
			GeometryStreamMetadata gsm = (GeometryStreamMetadata) getGeometryData(entity, GeomStreamComponent.TILE_DESCRIPTORS, null);
			AttributeColumnData result = new AttributeColumnData();
			result.id = entity.id;
			result.metadata = entity.publicMetadata;
			result.metadataTileDescriptors = gsm.metadataTileDescriptors;
			result.geometryTileDescriptors = gsm.geometryTileDescriptors;
			return result;
		}
		
		//TODO - check if entity is a table
		
		String query = entity.privateMetadata.get(PrivateMetadata.SQLQUERY);
		int tableId = DataConfig.NULL;
		String tableField = null;
		
		if (Strings.isEmpty(query))
		{
			String entityType = entity.publicMetadata.get(PublicMetadata.ENTITYTYPE);
			tableField = entity.privateMetadata.get(PrivateMetadata.SQLCOLUMN);
			
			if (!Strings.equal(entityType, EntityType.COLUMN))
				throw new RemoteException(String.format("Entity %s has no sqlQuery and is not a column (entityType=%s)", entity.id, entityType));
			
			if (Strings.isEmpty(tableField))
				throw new RemoteException(String.format("Entity %s has no sqlQuery and no sqlColumn private metadata", entity.id));
			
			// if there's no query, the query lives in the table entity instead of the column entity
			DataConfig config = getDataConfig();
			List<Integer> parentIds = config.getParentIds(entity.id);
			Map<Integer, String> idToType = config.getEntityTypes(parentIds);
			for (int id : parentIds)
			{
				if (Strings.equal(idToType.get(id), EntityType.TABLE))
				{
					tableId = id;
					break;
				}
			}
		}
		
		String dataType = entity.publicMetadata.get(PublicMetadata.DATATYPE);
		
		List<String> keys = null;
		List<Double> numericData = null;
		List<String> stringData = null;
		List<Object> thirdColumn = null; // hack for dimension slider format
		List<PGGeom> geometricData = null;

		boolean getRealKeys = true;
		boolean getRealData = true;
		String fakeData = entity.publicMetadata.get("fakeData");
		if (!Strings.isEmpty(fakeData))
		{
			FakeDataProperties props;
			try
			{
				props = GSON.fromJson(fakeData, FakeDataProperties.class);
			}
			catch (Exception e)
			{
				throw new RemoteException(String.format("Unable to retrieve data for column %s (Invalid \"fakeData\" JSON)", columnId));
			}
			
			getRealKeys = props.realKeys;
			getRealData = false;
			
			String title = entity.publicMetadata.get(PublicMetadata.TITLE);
			String keyType = entity.publicMetadata.get(PublicMetadata.KEYTYPE);
			String sqlParamsStr = "key";
			if (sqlParams != null)
				sqlParamsStr = GSON.toJson(sqlParams);
			
			if (!getRealKeys)
				keys = props.generateStrings(sqlParamsStr);
			
			if (Strings.equal(dataType, DataType.NUMBER) || Strings.equal(dataType, DataType.DATE))
			{
				int seed = title.hashCode() ^ keyType.hashCode() ^ sqlParamsStr.hashCode();
				numericData = props.generateDoubles(seed);
			}
			else
				stringData = props.generateStrings(title);
		}
		
		if (!Strings.isEmpty(query) && (getRealKeys || getRealData))
		{
			ConnectionInfo connInfo = getColumnConnectionInfo(entity);
			
			keys = new ArrayList<String>();
			
			////// begin MIN/MAX code
			
			// use config min,max or param min,max to filter the data
			double minValue = Double.NaN;
			double maxValue = Double.NaN;
			
			// server min,max values take priority over user-specified params
			if (entity.publicMetadata.containsKey(PublicMetadata.MIN))
			{
				try {
					minValue = Double.parseDouble(entity.publicMetadata.get(PublicMetadata.MIN));
				} catch (Exception e) { }
			}
			else
			{
				minValue = minParam;
			}
			if (entity.publicMetadata.containsKey(PublicMetadata.MAX))
			{
				try {
					maxValue = Double.parseDouble(entity.publicMetadata.get(PublicMetadata.MAX));
				} catch (Exception e) { }
			}
			else
			{
				maxValue = maxParam;
			}
			
			if (Double.isNaN(minValue))
				minValue = Double.NEGATIVE_INFINITY;
			
			if (Double.isNaN(maxValue))
				maxValue = Double.POSITIVE_INFINITY;
			
			////// end MIN/MAX code
			
			try
			{
				Connection conn = getStaticReadOnlyConnection(connInfo);
				
				// use default sqlParams if not specified by query params
				if (sqlParams == null || sqlParams.length == 0)
				{
					String sqlParamsString = entity.privateMetadata.get(PrivateMetadata.SQLPARAMS);
					sqlParams = CSVParser.defaultParser.parseCSVRow(sqlParamsString, true);
				}
				
				SQLResult result = SQLUtils.getResultFromQuery(conn, query, sqlParams, false);
				
				// if dataType is defined in the config file, use that value.
				// otherwise, derive it from the sql result.
				if (Strings.isEmpty(dataType))
				{
					dataType = DataType.fromSQLType(result.columnTypes[1]);
					entity.publicMetadata.put(PublicMetadata.DATATYPE, dataType); // fill in missing metadata for the client
				}
				
				if (!getRealData)
				{
					// do nothing
				}
				else if (dataType.equalsIgnoreCase(DataType.NUMBER)) // special case: "number" => Double
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
				if (getRealData && result.columnTypes.length == 3)
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
					else if (stringData != null)
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
				throw new RemoteException("Unexpected error", e);
			}
		}

		AttributeColumnData result = new AttributeColumnData();
		result.id = entity.id;
		result.tableId = tableId;
		result.tableField = tableField;
		result.metadata = entity.publicMetadata;
		if (keys != null)
			result.keys = keys.toArray(new String[keys.size()]);
		if (numericData != null)
			result.data = numericData.toArray();
		else if (geometricData != null)
			result.data = geometricData.toArray();
		else if (stringData != null)
			result.data = stringData.toArray();
		// hack for dimension slider
		if (thirdColumn != null)
			result.thirdColumn = thirdColumn.toArray();
		
		// truncate fake data or keys if necessary
		if ((!getRealData || !getRealKeys) && result.keys != null && result.data != null && result.keys.length != result.data.length)
		{
			int minLength = Math.min(result.keys.length, result.data.length);
			result.keys = Arrays.copyOf(result.keys, minLength);
			result.data = Arrays.copyOf(result.data, minLength);
		}
		
		return result;
	}
	
	public TableData getTable(int id, Object[] sqlParams) throws RemoteException
	{
		DataEntity entity = getDataConfig().getEntity(id);
		ConnectionInfo connInfo = getColumnConnectionInfo(entity);
		String query = entity.privateMetadata.get(PrivateMetadata.SQLQUERY);
		Map<String, Object[]> data = new HashMap<String, Object[]>();
		try
		{
			Connection conn = getStaticReadOnlyConnection(connInfo);
			
			// use default sqlParams if not specified by query params
			if (sqlParams == null || sqlParams.length == 0)
			{
				String sqlParamsString = entity.privateMetadata.get(PrivateMetadata.SQLPARAMS);
				sqlParams = CSVParser.defaultParser.parseCSVRow(sqlParamsString, true);
			}
			
			SQLResult result = SQLUtils.getResultFromQuery(conn, query, sqlParams, false);
			
			// transpose
			int iColCount = result.columnNames.length;
			int iRowCount = result.rows.length;
			for (int iCol = 0; iCol < iColCount; iCol++)
			{
				Object[] column = new Object[result.rows.length];
				for (int iRow = 0; iRow < iRowCount; iRow++)
					column[iRow] = result.rows[iRow][iCol];
				data.put(result.columnNames[iCol], column);
			}
		}
		catch (SQLException e)
		{
			System.err.println(query);
			e.printStackTrace();
			throw new RemoteException(String.format("Unable to retrieve data for table %s", id));
		}
		catch (NullPointerException e)
		{
			e.printStackTrace();
			throw new RemoteException("Unexpected error", e);
		}
		
		TableData result = new TableData();
		result.id = id;
		result.keyColumns = CSVParser.defaultParser.parseCSVRow(entity.privateMetadata.get(PrivateMetadata.SQLKEYCOLUMN), true);
		result.columns = data;
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
		if (columnIds == null)
			columnIds = new int[0];
		if (columnIds.length > MAX_COLUMN_REQUEST_COUNT)
			throw new RemoteException(String.format("You cannot request more than %s columns at a time.", MAX_COLUMN_REQUEST_COUNT));
		
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
		if (tileIDs == null || tileIDs.length == 0)
			throw new RemoteException("At least one tileID must be specified.");
		return (byte[]) getGeometryData(entity, GeomStreamComponent.METADATA_TILES, tileIDs);
	}
	
	public byte[] getGeometryStreamGeometryTiles(int columnId, int[] tileIDs) throws RemoteException
	{
		DataEntity entity = getColumnEntity(columnId);
		if (tileIDs == null || tileIDs.length == 0)
			throw new RemoteException("At least one tileID must be specified.");
		return (byte[]) getGeometryData(entity, GeomStreamComponent.GEOMETRY_TILES, tileIDs);
	}
	
	private static enum GeomStreamComponent { TILE_DESCRIPTORS, METADATA_TILES, GEOMETRY_TILES };
	
	private Object getGeometryData(DataEntity entity, GeomStreamComponent component, int[] tileIDs) throws RemoteException
	{
		assertStreamingGeometryColumn(entity, true);
		
		Connection conn = getStaticReadOnlyConnection(getColumnConnectionInfo(entity));
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
		params.setPublicValues(
				PublicMetadata.ENTITYTYPE, EntityType.COLUMN,
				PublicMetadata.KEYTYPE, keyType
			);
		List<Integer> columnIds = new ArrayList<Integer>( dataConfig.searchPublicMetadata(params.publicMetadata, null) );

		if (columnIds.size() > MAX_COLUMN_REQUEST_COUNT)
			columnIds = columnIds.subList(0, MAX_COLUMN_REQUEST_COUNT);
		return DataService.getFilteredRows(ListUtils.toIntArray(columnIds), null, keysArray);
	}
	
	/**
	 * Gets all column IDs referenced by this object and its nested objects.
	 */
	private static Collection<Integer> getReferencedColumnIds(NestedColumnFilters filters)
	{
		Set<Integer> ids = new HashSet<Integer>();
		if (filters.cond != null)
			ids.add(((Number)filters.cond.f).intValue());
		else
			for (NestedColumnFilters nested : (filters.and != null ? filters.and : filters.or))
				ids.addAll(getReferencedColumnIds(nested));
		return ids;
	}
	
	/**
	 * Converts nested ColumnFilter.f values from a column ID to the corresponding SQL field name.
	 * @param filters
	 * @param entities
	 * @return A copy of filters with field names in place of the column IDs.
	 * @see ColumnFilter#f
	 */
	private static NestedColumnFilters convertColumnIdsToFieldNames(NestedColumnFilters filters, Map<Integer, DataEntity> entities)
	{
		if (filters == null)
			return null;
		
		NestedColumnFilters result = new NestedColumnFilters();
		if (filters.cond != null)
		{
			result.cond = new ColumnFilter();
			result.cond.v = filters.cond.v;
			result.cond.r = filters.cond.r;
			result.cond.f = entities.get(((Number)filters.cond.f).intValue()).privateMetadata.get(PrivateMetadata.SQLCOLUMN);
		}
		else
		{
			NestedColumnFilters[] in = (filters.and != null ? filters.and : filters.or);
			NestedColumnFilters[] out = new NestedColumnFilters[in.length];
			for (int i = 0; i < in.length; i++)
				out[i] = convertColumnIdsToFieldNames(in[i], entities);
			if (filters.and == in)
				result.and = out;
			else
				result.or = out;
		}
		return result;
	}
	
	private static SQLResult getFilteredRowsFromSQL(Connection conn, String schema, String table, int[] columns, NestedColumnFilters filters, Map<Integer,DataEntity> entities) throws SQLException
	{
		String[] quotedFields = new String[columns.length];
		for (int i = 0; i < columns.length; i++)
			quotedFields[i] = SQLUtils.quoteSymbol(conn, entities.get(columns[i]).privateMetadata.get(PrivateMetadata.SQLCOLUMN));
		
		WhereClause<Object> where = WhereClause.fromFilters(conn, convertColumnIdsToFieldNames(filters, entities));

		String query = String.format(
			"SELECT %s FROM %s %s",
			Strings.join(",", quotedFields),
			SQLUtils.quoteSchemaTable(conn, schema, table),
			where.clause
		);
		
		return SQLUtils.getResultFromQuery(conn, query, where.params.toArray(), false);
	}
	
	@SuppressWarnings("unchecked")
	public static WeaveRecordList getFilteredRows(int[] columns, NestedColumnFilters filters, String[] keysArray) throws RemoteException
	{
		if (columns == null || columns.length == 0)
			throw new RemoteException("At least one column must be specified.");
		
		if (filters != null)
			filters.assertValid();
		
		DataConfig dataConfig = getDataConfig();
		WeaveRecordList result = new WeaveRecordList();
		Map<Integer, DataEntity> entityLookup = new HashMap<Integer, DataEntity>();
		
		{
			// get all column IDs whether or not they are to be selected.
			Set<Integer> allColumnIds = new HashSet<Integer>();
			if (filters != null)
				allColumnIds.addAll(getReferencedColumnIds(filters));
			for (int id : columns)
				allColumnIds.add(id);
			// get all corresponding entities
			for (DataEntity entity : dataConfig.getEntities(allColumnIds, true))
				entityLookup.put(entity.id, entity);
			// check for missing columns
			for (int id : allColumnIds)
				if (entityLookup.get(id) == null)
					throw new RemoteException("No column with ID=" + id);
			
			// provide public metadata in the same order as the selected columns
			result.attributeColumnMetadata = new Map[columns.length];
			for (int i = 0; i < columns.length; i++)
				result.attributeColumnMetadata[i] = entityLookup.get(columns[i]).publicMetadata;
		}
		
		String keyType = result.attributeColumnMetadata[0].get(PublicMetadata.KEYTYPE);
		// make sure all columns have same keyType
		for (int i = 1; i < columns.length; i++)
			if (!Strings.equal(keyType, result.attributeColumnMetadata[i].get(PublicMetadata.KEYTYPE)))
				throw new RemoteException("Specified columns must all have same keyType.");

		if (keysArray == null)
		{
			boolean canGenerateSQL = true;
			// check to see if all the columns are from the same SQL table.
			String connection = null;
			String sqlSchema = null;
			String sqlTable = null;
			for (DataEntity entity : entityLookup.values())
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
				Connection conn = getColumnConnectionInfo(entityLookup.get(columns[0])).getStaticReadOnlyConnection();
				try
				{
					result.recordData = getFilteredRowsFromSQL(conn, sqlSchema, sqlTable, columns, filters, entityLookup).rows;
				}
				catch (SQLException e)
				{
					throw new RemoteException("getFilteredRows() failed.", e);
				}
			}
		}
		
		if (result.recordData == null)
		{
			throw new Error("Selecting across tables is not supported yet.");
			/*
			HashMap<String,Object[]> data = new HashMap<String,Object[]>();
			if (keysArray != null)
				for (String key : keysArray)
					data.put(key, new Object[entities.length]);
			
			for (int colIndex = 0; colIndex < entities.length; colIndex++)
			{
				Object[] filters = fcrs[colIndex].filters;
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
				
//				 * columnInfoArray = config.getDataEntity(params);
//				 * for each info in columnInfoArray
//				 *      get sql data
//				 *      for each row in sql data
//				 *            if key is in keys array,
//				 *                  add this value to the result
//				 * return result
				
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
					if (Strings.isEmpty(dataType))
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
										Object[] prevFilters = fcrs[i].filters;
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
				List<String> keys = new LinkedList<String>();
				for (Entry<String,Object[]> entry : data.entrySet())
					if (entry.getValue() != null)
						keys.add(entry.getKey());
				keysArray = keys.toArray(new String[keys.size()]);
			}
			
			Object[][] rows = new Object[keysArray.length][];
			for (int iKey = 0; iKey < keysArray.length; iKey++)
				rows[iKey] = data.get(keysArray[iKey]);
			
			result.recordData = rows;
			*/
		}
		
		result.keyType = keyType;
		result.recordKeys = keysArray;
		
		return result;
	}

	/////////////////////////////
	// backwards compatibility
	
	
	/**
	 * Use getHierarchyInfo() instead. This function is provided for backwards compatibility only.
	 * @deprecated
	 */
	@Deprecated public EntityHierarchyInfo[] getDataTableList() throws RemoteException
	{
		return getDataConfig().getEntityHierarchyInfo(MapUtils.<String,String>fromPairs(PublicMetadata.ENTITYTYPE, EntityType.TABLE));
	}

	/**
	 * Use getEntities() instead. This function is provided for backwards compatibility only.
	 * @deprecated
	 */
	@Deprecated public int[] getEntityChildIds(int parentId) throws RemoteException
	{
		return ListUtils.toIntArray( getDataConfig().getChildIds(parentId) );
	}
	
	/**
	 * Use getEntities() instead. This function is provided for backwards compatibility only.
	 * @deprecated
	 */
	@Deprecated public int[] getParents(int childId) throws RemoteException
	{
		int[] ids = ListUtils.toIntArray( getDataConfig().getParentIds(childId) );
		Arrays.sort(ids);
		return ids;
	}
	
	/**
	 * Use findEntityIds() instead. This function is provided for backwards compatibility only.
	 * @deprecated
	 */
	@Deprecated
	public int[] getEntityIdsByMetadata(Map<String,String> publicMetadata, int entityType) throws RemoteException
	{
		publicMetadata.put(PublicMetadata.ENTITYTYPE, EntityType.fromInt(entityType));
		return findEntityIds(publicMetadata, null);
	}
	
	/**
	 * Use getEntities() instead. This function is provided for backwards compatibility only.
	 * @deprecated
	 */
	@Deprecated
	public DataEntity[] getEntitiesById(int[] ids) throws RemoteException
	{
		return getEntities(ids);
	}
	
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
		
		metadata.put(PublicMetadata.ENTITYTYPE, EntityType.COLUMN);
		
		final String DATATABLE = "dataTable";
		final String NAME = "name";
		
		// exclude these parameters from the query
		if (metadata.containsKey(NAME))
			metadata.remove(PublicMetadata.TITLE);
		String minStr = metadata.remove(PublicMetadata.MIN);
		String maxStr = metadata.remove(PublicMetadata.MAX);
		String paramsStr = metadata.remove(PrivateMetadata.SQLPARAMS);
		
		DataConfig dataConfig = getDataConfig();
		
		Collection<Integer> ids = dataConfig.searchPublicMetadata(metadata, null);
		
		// attempt recovery for backwards compatibility
		if (ids.size() == 0)
		{
			if (metadata.containsKey(DATATABLE) && metadata.containsKey(NAME))
			{
				// try to find columns sqlTable==dataTable and sqlColumn=name
				Map<String,String> privateMetadata = new HashMap<String,String>();
				String sqlTable = metadata.get(DATATABLE);
				String sqlColumn = metadata.get(NAME);
				for (int i = 0; i < 2; i++)
				{
					if (i == 1)
						sqlTable = sqlTable.toLowerCase();
					privateMetadata.put(PrivateMetadata.SQLTABLE, sqlTable);
					privateMetadata.put(PrivateMetadata.SQLCOLUMN, sqlColumn);
					ids = dataConfig.searchPrivateMetadata(privateMetadata, null);
					if (ids.size() > 0)
						break;
				}
			}
			else if (metadata.containsKey(NAME)
					&& Strings.equal(metadata.get(PublicMetadata.DATATYPE), DataType.GEOMETRY))
			{
				metadata.put(PublicMetadata.TITLE, metadata.remove(NAME));
				ids = dataConfig.searchPublicMetadata(metadata, null);
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
