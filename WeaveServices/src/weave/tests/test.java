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
import weave.servlets.RService;

public class test
{

	static RService ws = null;
	public static void call(String[] inputNames, Object[][] inputValues, String[] outputNames, String script, String plotScript, boolean showIntermediateResults, boolean showWarnings) throws Exception{
		
		RResult[] scriptResult = null;
//		try {
//			scriptResult =	ws.runScript(null, inputNames, inputValues, outputNames, script, plotScript, showIntermediateResults, showWarnings);
//		} catch (RemoteException e) {
//			e.printStackTrace();
//		}
//		finally{
//			System.out.println(scriptResult);
//		}
	}
	
	public static void main(String[] args) throws Exception {
		// TODO Auto-generated method stub
		System.out.println("hi");		
		ws = new RService();
	
		
		String[] inputNames = {};
		Object[][] inputValues = {};			
		String plotscript = "";
		String script = "";		
		String [] resultNames = {};	
		
		Object[] array1 = {0,10,20,30,Double.NaN,50,60,55,89,33,44,54,21};
		Object[] array2 = {10,20,Double.NaN,52,34,87,45,65,76,87,23,12,34};
		//String[] keys = {"a","b","c","d","e","f"};
//		//Object[] array3 = {"aa","bb","cc","dd","ee","ff"};
		
//		plotscript ="";
//		script = "x<-5";
//		inputNames = new String[]{};
//		inputValues = new Object[][]{};
//		resultNames = new String []{"x"};
//		keys = new  String[]{};
//		call(inputNames,inputValues,resultNames,script,plotscript,false,false);
//		
//		inputNames =  new String []{"x","y"};
//		inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"0","1","2","3","4","5"};
//		plotscript = "plot(x,y)";
//		script = "df<-data.frame(x,y)";		
//		resultNames =  new String []{"df"};			
//		call(inputNames,inputValues,resultNames,script,plotscript,false,false);	
		

		inputNames =  new String []{"x","y"};
	inputValues = new Object[][]{array1,array2};	
//		keys = new String []{"a","b","c","d","e","f"};
//		//plotscript = "plot(x,y)";
//		script = "fun<-function(arg1){\n" +
//				"ans<-(arg1) + 5\n" +
//				"return(ans)}\n" +
//				"d<-lapply(x,fun)";		
//		resultNames =  new String []{"d"};			
//		call(inputNames,inputValues,resultNames,script,plotscript,false,false);
		
		inputNames =  new String []{"x","y"};
		inputValues = new Object[][]{array1,array2};
		//plotscript = "plot(x,y)";
		//keys = new  String[]{};
		//script = "d<-x[x>20]";	
		script = " Bind<- cbind(x,y) \n library(norm) \n pre<-prelim.norm(Bind) \n Em <- em.norm(pre) \n rngseed(34215) \n " +
					"Da <- da.norm(pre, Em, steps = 20) \n imp <- imp.norm(pre, Da, Bind) ";
		//script = "x <- 5\n y<- 6";
		resultNames =  new String []{"pre$nmis","imp" };			
		call(inputNames,inputValues,resultNames,script,plotscript,true,false);
		
	}
}
