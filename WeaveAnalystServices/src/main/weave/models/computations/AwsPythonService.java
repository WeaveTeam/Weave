package weave.models.computations;

import java.io.File;
import java.io.FileReader;

import org.python.core.PyObject;
import org.python.util.PythonInterpreter;

import weave.models.ScriptManagerService;
import weave.servlets.WeaveServlet;

import com.xhaus.jyson.JSONEncodeError;
import com.xhaus.jyson.JysonCodec;

public class AwsPythonService {

	public Object runScript(String scriptAbspath, Object[][] dataset) throws JSONEncodeError {
		
		PythonInterpreter pythonI = new PythonInterpreter();
		PyObject pyResult = new PyObject();
		Object finalResult = new Object();
		// #1 assign the variables
		pythonI.set("dataset", dataset);
		pythonI.execfile(scriptAbspath);
		
		pyResult = pythonI.get("result");//TODO hardcoded for now as a result all scripts will return contents as 'result'
		/* we do the next step to convert the PyArray Object into a json string which can then be used to generate a java Object
		 * Java object is converted by GSON in the Weave Servlet into a json string 
		 * Python Object .........> Json string ........> JavaObject ...........> Json string*/
		String tempJsonString = JysonCodec.dumps(new PyObject[]{pyResult}, new String[]{""});//produces the string
		
		finalResult = WeaveServlet.GSON.fromJson(tempJsonString, Object.class);//produces a java object
		//this is sent to the Weave Servlet(handleJsonResponses())
		return finalResult;
	}
	
	//alternative ways for evaluating a code object and returning the result without using the pythoninterpreter.get() method 
	//no success yet
	public PyObject checking(Object[][] dataset){
		PyObject answer = new PyObject();
		PythonInterpreter pythonI = new PythonInterpreter();
		pythonI.set("dataset", dataset);
		FileReader reader =null;
//		try {
//			reader = new FileReader(new File("testpython.py"));
//		} catch (FileNotFoundException e) {
//			e.printStackTrace();
//		}
//		PyCode codeObj = pythonI.compile(reader);
//		answer = pythonI.eval(codeObj);
		
		//2
		String script = null;
		try {
			script = ScriptManagerService.getScript(new File("C:\\Users\\Shweta\\Desktop\\"), "testpython.py");
		} catch (Exception e) {
			e.printStackTrace();
		}
		answer = pythonI.eval(script);
		
		
		return answer;
	}
	
}
