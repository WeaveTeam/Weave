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

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.URL;
import java.rmi.RemoteException;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import org.apache.commons.io.IOUtils;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import weave.beans.AttributeColumnDataWithKeys;
import weave.beans.DataServiceMetadata;
import weave.beans.DataTableMetadata;
import weave.beans.GXAResult;
import weave.beans.GeometryStreamMetadata;
import weave.beans.WeaveRecordList;
import weave.config.DublinCoreUtils;
import weave.config.ISQLConfig;
import weave.config.ISQLConfig.AttributeColumnInfo;
import weave.config.ISQLConfig.AttributeColumnInfo.DataType;
import weave.config.ISQLConfig.AttributeColumnInfo.Metadata;
import weave.config.ISQLConfig.ConnectionInfo;
import weave.config.ISQLConfig.DatabaseConfigInfo;
import weave.config.ISQLConfig.GeometryCollectionInfo;
import weave.config.SQLConfigManager;
import weave.config.SQLConfigUtils;
import weave.geometrystream.SQLGeometryStreamReader;
import weave.reports.WeaveReport;
import weave.utils.CSVParser;
import weave.utils.DebugTimer;
import weave.utils.ListUtils;
import weave.utils.SQLResult;

public class GXAService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public GXAService()
	{
	}
	
	private int rows;
    private int start;
    private boolean all;

    private final List<String> experimentKeywords = new ArrayList<String>();
    private final List<String> factors = new ArrayList<String>();
    private final List<String> anyFactorValues = new ArrayList<String>();
   // public void extractGeneExpressionData(String geneIsValue, String speciesValue , String rowsValue, String startValue)throws IOException{
	public void extractGeneExpressionData()throws IOException{
		String urlString = "http://www.ebi.ac.uk/gxa/api/vx?geneGeneIs=ENSG00000066279+ENSG00000109956&updownIn=EFO_0000815+EFO_0000887&rows=50&start=0&format=json";

		//String urlString = "http://www.ebi.ac.uk/gxa/api/vx?geneIs="+geneIsValue+"&species="+speciesValue;
		String jsonString = stringOfUrl(urlString);
		GXAResult gxaResult = new Gson().fromJson(jsonString, GXAResult.class);
//		JsonElement jElement = new JsonParser().parse(jsonString);
//		JsonObject  jobject = jElement.getAsJsonObject();
//		JsonArray jarray = jobject.getAsJsonArray("results");
//		jobject = jarray.get(1).getAsJsonObject();
//		JsonArray jarrayExpressions = jobject.getAsJsonArray("expressions");
//		
//		GXAResult gxaResult = new Gson().fromJson(jarrayExpressions.get(1).getAsJsonObject(), GXAResult.class);
		System.out.println(gxaResult);
	}
	
	public static String stringOfUrl(String addr) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        URL url = new URL(addr);
        IOUtils.copy(url.openStream(), output);
        return output.toString();
    }
}
