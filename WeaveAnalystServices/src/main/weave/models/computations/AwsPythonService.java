package weave.models.computations;

import java.io.File;
import java.io.FileReader;

import org.python.core.PyObject;
import org.python.util.PythonInterpreter;

import weave.models.ScriptManagerService;

public class AwsPythonService {

	public PyObject runScript(String scriptAbspath, Object[][] dataset){
		
		PythonInterpreter pythonI = new PythonInterpreter();
		// #1 assign the variables
		pythonI.set("dataset", dataset);
		PyObject result = new PyObject();
		try
		{
			//pythonI.execfile("testpython.py");//calling script
			pythonI.execfile(scriptAbspath);
			result = pythonI.get("result");//TODO hardcoded for now as a result all scripts will return contents as 'result'
		}
		catch(Exception e)
		{
			e.printStackTrace();
			System.out.println("Error");
		}
		
		System.out.println("answer:" + result);
		return result;
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
