package weave.tests;

import java.sql.Connection;
import java.util.Arrays;
import java.util.Map;

import weave.utils.MapUtils;
import weave.utils.SQLUtils;

public class SQLServerTest 
{
	public static void main(String[] args)
	{
		try
		{
			String sqlDriver = SQLUtils.getDriver(SQLUtils.SQLSERVER);
			String connectString = SQLUtils.getConnectString(SQLUtils.SQLSERVER, "localhost", "1433", "<INSTNANCE_NAME>", "<USERNAME>", "<PASSWORD>");
			Connection conn = SQLUtils.getConnection(sqlDriver, connectString);
			Map<String, Object> valueMap = MapUtils.fromPairs(
				"First Name", "fName",
				"Last Name", "lName",
				"Age", 22,
				"Grade", "A"
			);
			String[] columnNames = {"First Name", "Last Name", "Age", "Grade"};
			String[] columnTypes = {"VARCHAR(20)", "VARCHAR(20)", "int", "VARCHAR(5)"};
			
			SQLUtils.createTable(conn, "dbo", "testTable2", Arrays.asList(columnNames), Arrays.asList(columnTypes), null);
			SQLUtils.insertRow(conn, "dbo", "testTable2", valueMap);
		}
		catch (Exception e)
		{
			System.out.println(e);
		}
		
		
	}
}
