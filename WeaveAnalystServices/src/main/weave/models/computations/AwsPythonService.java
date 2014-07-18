package weave.models.computations;

import org.python.core.PyObject;
import org.python.util.PythonInterpreter;

public class AwsPythonService {

	public PyObject runScript(String scriptAbspath, Object[][] dataset){
		
		// #1 assign the variables
		PyObject result = new PyObject();
		PythonInterpreter pythonI = new PythonInterpreter();
		pythonI.set("dataset", dataset);
		try
		{
			//pythonI.execfile("testpython.py");//calling script
			pythonI.execfile(scriptAbspath);
			result = pythonI.get("result");//TODO hardcoded for now
		}
		catch(Exception e)
		{
			System.out.println("Error");
		}
		
		System.out.println("answer:" + result);
		return result;
	}
	
}
