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




import org.apache.commons.io.IOUtils;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import weave.beans.GXA.GXAResult;


public class GXAService extends GenericServlet
{
	private static final long serialVersionUID = 1L;
	
	public GXAService()
	{
	}
	
   // public void extractGeneExpressionData(String geneIsValue, String speciesValue , String rowsValue, String startValue)throws IOException{
	public GXAResult extractGeneExpressionData(String queryUrl)throws IOException{
		//queryUrl = "http://www.ebi.ac.uk/gxa/api/vx?geneGeneIs=ENSG00000066279+ENSG00000109956&updownIn=EFO_0000815+EFO_0000887&rows=50&start=0&format=json";

		//String urlString = "http://www.ebi.ac.uk/gxa/api/vx?geneIs="+geneIsValue+"&species="+speciesValue;
		String jsonString = stringOfUrl(queryUrl);
		GXAResult gxaResult = new Gson().fromJson(jsonString, GXAResult.class);
//		JsonElement jElement = new JsonParser().parse(jsonString);
//		JsonObject  jobject = jElement.getAsJsonObject();
//		JsonArray jarray = jobject.getAsJsonArray("results");
//		jobject = jarray.get(1).getAsJsonObject();
//		JsonArray jarrayExpressions = jobject.getAsJsonArray("expressions");
//		
//		GXAResult gxaResult = new Gson().fromJson(jarrayExpressions.get(1).getAsJsonObject(), GXAResult.class);
		System.out.println(gxaResult);
		return gxaResult;
	}
	//object name is built on dynamic object name - queryValue
	// so didn't used the new Gson().fromJson method
	public JsonArray getGeneList(String queryValue) throws IOException{
		String queryURL = "http://www.ebi.ac.uk/gxa/fval?q=" + queryValue+ "&factor=&type=gene&limit=15";
		String jsonString = stringOfUrl(queryURL);
		JsonElement jElement = new JsonParser().parse(jsonString);
		JsonObject  jobject = jElement.getAsJsonObject();
		JsonObject completionsJObj = jobject.getAsJsonObject("completions");
		JsonArray jsonArray = completionsJObj.getAsJsonArray(queryValue);
//		jobject = jarray.get(1).getAsJsonObject();
//		JsonArray jarrayExpressions = jobject.getAsJsonArray("expressions");
		return jsonArray;
	}
	
	public static String stringOfUrl(String addr) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        URL url = new URL(addr);
        IOUtils.copy(url.openStream(), output);
        return output.toString();
    }
}
