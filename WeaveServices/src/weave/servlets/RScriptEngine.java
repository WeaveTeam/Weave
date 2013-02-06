package weave.servlets;

import java.util.Map;

import javax.script.Bindings;
import javax.script.ScriptContext;
import javax.script.ScriptException;

import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REngine;
import org.rosuda.REngine.REngineException;

import weave.utils.RUtils;

/**
 * R implementation of ScriptEngine using REngine (JRI). 
 */
public class RScriptEngine extends JRIBaseScriptEngine  {

	/** Underlying R implementation. */
 	protected REngine engine;

 	/**
 	 * Create the ScriptEngine with the given R implementation.
 	 * @param engine The REngine implementation.
 	 */
	public RScriptEngine(REngine engine) {
		
		this.engine = engine;
		try {
			// setup the cache of Opaque objects that maybe passed to and fro
			myEval(JRIOpaque.name + " = list()");
		}
		catch(Exception e) {
			throw new RuntimeException(e);
		}
	}

	public Object eval(String script, ScriptContext context) throws ScriptException {
		if(context != null) {
			Bindings bindings = context.getBindings(ScriptContext.ENGINE_SCOPE);
			if(bindings != null) {
				for(Map.Entry<String, Object> entry : bindings.entrySet()) {
					assignArg(entry.getKey(), entry.getValue());
				}
			}
		}
		try {
			REXP rexp = myEval(script);
			return RUtils.rexp2jobj(rexp);
		}
		catch(Exception rme) {
			throw new ScriptException(rme);
		}
	}



	public boolean close() {
		return engine.close();
	}

	/** Internal eval method. */
	private REXP myEval(String cmd) throws REngineException, REXPMismatchException {
		return engine.parseAndEval(cmd);
	}

	/** Return a string representation of the function argument and other setup. */
	private String assignArg(String name, Object value) {
		if(value == null) {
			name = "NULL";
		}
		else if(value instanceof JRIOpaque) {
			name = value.toString();
		}
		else {
			try {
				engine.assign(name, RUtils.jobj2rexp(value), null);
			}
			catch(Exception e) {
				throw new RuntimeException(e);
			}
		}
		return name;
	}

}
