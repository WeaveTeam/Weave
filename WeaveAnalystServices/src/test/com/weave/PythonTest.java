package com.weave;

import java.io.FileReader;
import java.io.StringWriter;

import javax.script.ScriptContext;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.SimpleScriptContext;

import org.python.util.PythonInterpreter;
import org.python.core.*;

import weave.models.computations.AwsPythonService;

public class PythonTest {
	
//	public static void main(String a[]) throws Exception 
//	{
//		/* 
//		 * sending variables, adding them in python and printing the output
//		 * Uses python interpreter
//		 */
//		PythonInterpreter pythonI = new PythonInterpreter();
////		int num1 = 100;
////		int num2 = 899;
////		 
////		pythonI.set("input1", new PyInteger(num1));
////		pythonI.set("input2", new PyInteger(num2));
////		pythonI.exec("answer = input1+input2");
////		PyObject result = pythonI.get("answer");
////		System.out.println("val :" + result);
//		
//		/*
//		 * Executing a python script from a file and retrieving/printing the output
//		 * Uses python interpreter
//		 */
//		
//		//set the variables to be used in namespace, we pass in parameters here
//		pythonI.set("input", new PyInteger(4));
//		
//		try
//		{
//			pythonI.execfile("testpython.py");//calling script
//			PyObject result = pythonI.get("result");//obtaining result
//			System.out.println("answer:" + result);
//		}
//		catch(Exception e)
//		{
//			System.out.println("Error");
//		}
//		
//		
//		
//		
//		/* another alternative way of executing scripts, 
//		 * does NOT use the python interpreter
//		 * 
//		 */
////		StringWriter mywriter = new StringWriter();
////		ScriptEngineManager mymanager = new ScriptEngineManager();
////		ScriptContext mycontext = new SimpleScriptContext();
////		
////		mycontext.setWriter(mywriter);
////		ScriptEngine engine = mymanager.getEngineByName("python");
////		engine.eval(new FileReader("testpython.py"), mycontext);
////		System.out.println(mywriter.toString()); 
////		
//		
//		
//	}
	
	public static void main(String a[]) throws Exception{
		AwsPythonService aps = new AwsPythonService();
		//PyInteger dataset = new PyInteger(1098);
		Object[] array1 = {10.39573495,1020.56530,22.67645,5.34567456,60.4574567,55.7897043568,89.787969,33.56767,-0.67676868544,5.8888884,21.89897,343.43,234343.34};
		Object[] array2 = {33.56767,-0.67676868544,5.8888884,21.89897,5,6,7,8,9,10,11,12,13};
		Object[][]dataset = new Object[][]{array1, array2};
		String scriptAbsPath = "BioTest.py";
		//aps.checking(dataset);
		//Object d = aps.runScript(scriptAbsPath, dataset);
	}

}
