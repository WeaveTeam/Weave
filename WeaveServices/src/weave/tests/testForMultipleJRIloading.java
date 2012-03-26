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
package weave.tests;


import java.rmi.RemoteException;
import weave.beans.RResult;
import weave.servlets.JRIService;
public class testForMultipleJRIloading {

	/**
	 * @param args
	 * @throws Exception 
	 */


	static JRIService ws = null;
	public static void call(String[] keys,String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings, boolean useColumnAsList) throws Exception{
		
		RResult[] scriptResult = null;
		try {
			scriptResult =	ws.runScript(keys,inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings,useColumnAsList);
		} catch (RemoteException e) {
			e.printStackTrace();
		}
		finally{
			System.out.println(scriptResult);
		}
	}
	
	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		System.out.println("hi");		
		ws = new JRIService();
	
		
		String[] inputNames = {};
		Object[][] inputValues = {};			
		String plotscript = "";
		String script = "";		
		String [] resultNames = {};	
		
		Object[] array1 = {0,10,20,30,40,50};
		Object[] array2 = {10,20,30,52,34,87};
		String[] keys = {"a","b","c","d","e","f"};
//		//Object[] array3 = {"aa","bb","cc","dd","ee","ff"};
		
//		plotscript ="";
//		script = "x<-5";
//		inputNames = new String[]{};
//		inputValues = new Object[][]{};
//		resultNames = new String []{"x"};
//		keys = new  String[]{};
//		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false);
//		
//		inputNames =  new String []{"x","y"};
//		inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"0","1","2","3","4","5"};
//		plotscript = "plot(x,y)";
//		script = "df<-data.frame(x,y)";		
//		resultNames =  new String []{"df"};			
//		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false);	
		

//		inputNames =  new String []{"x","y"};
//		inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"a","b","c","d","e","f"};
//		//plotscript = "plot(x,y)";
//		script = "fun<-function(arg1){\n" +
//				"ans<-(arg1) + 5\n" +
//				"return(ans)}\n" +
//				"d<-lapply(x,fun)";		
//		resultNames =  new String []{"d"};			
//		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false);
		
		inputNames =  new String []{"x","y"};
		inputValues = new Object[][]{array1,array2};
		//plotscript = "plot(x,y)";
		//keys = new  String[]{};
		script = "d<-x[x>20]";		
		resultNames =  new String []{"x","d"};			
		call(keys,inputNames,inputValues,resultNames,script,plotscript,false,false,false);
		
	}
}
