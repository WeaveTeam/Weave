package weave.servlets;
import static javax.script.ScriptEngine.ENGINE;
import static javax.script.ScriptEngine.ENGINE_VERSION;
import static javax.script.ScriptEngine.LANGUAGE;
import static javax.script.ScriptEngine.LANGUAGE_VERSION;
import static javax.script.ScriptEngine.NAME;

import java.util.Collections;
import java.util.List;

import javax.script.ScriptEngine;
import javax.script.ScriptEngineFactory;

import org.rosuda.REngine.REngine;

/**
 * R implementation of ScriptEngineFactory.
 * ScriptEngineFactory is used to describe and instantiate ScriptEngines.
 * Each class implementing "ScriptEngine" has a corresponding factory 
 * 		that exposes metadata describing the engine class. 
 * The "ScriptEngineManager" uses the service provider mechanism described in the "Jar File Specification" 
 *		 to obtain instances of all ScriptEngineFactories available in the current ClassLoader.
 */
public class RScriptFactory implements ScriptEngineFactory {

	private static final String R_ENGINE_NAME = "REngine";
	private static final String R_ENGINE_VERSION = "0.4";
	private static final String R_LANGUAGE_NAME = "R";
	private static final String R_LANGUAGE_VERSION = "2";
	private static final String R_FILE_EXTENSION = "R";
	private static final List<String> R_MIME_TYPES = null;

	public String getEngineName() {
		return R_ENGINE_NAME;
	}

	public String getEngineVersion() {
		return R_ENGINE_VERSION;
	}

	public String getLanguageName() {
		return R_LANGUAGE_NAME;
	}

	public String getLanguageVersion() {
		return R_LANGUAGE_VERSION;
	}

	public List<String> getNames() {
		return Collections.singletonList(R_ENGINE_NAME);
	}

	public List<String> getExtensions() {
		return Collections.singletonList(R_FILE_EXTENSION);
	}

	public List<String> getMimeTypes() {
		return R_MIME_TYPES;
	}

	public Object getParameter(String key) {
		if(key == null)						return null;
		if(key.equals(ENGINE))				return getEngineName();
		if(key.equals(ENGINE_VERSION))		return getEngineVersion();
		if(key.equals(LANGUAGE))			return getLanguageName();
		if(key.equals(LANGUAGE_VERSION))	return getLanguageVersion();
		if(key.equals(NAME))				return getNames().get(0);
		return null;
	}

	public String getMethodCallSyntax(String obj, String m, String... args) {
		String ret = "";
		return ret;
	}

	public String getOutputStatement(String toDisplay) {
		return  toDisplay ;
	}

	public String getProgram(String... statements) {
		String ret = "";		
		return ret;
	}

	public ScriptEngine getScriptEngine() {
		try {							
			REngine rEngine = REngine.engineForClass( "org.rosuda.REngine.JRI.JRIEngine");
			JRIBaseScriptEngine engine = new RScriptEngine(rEngine);
			engine.setFactory(this);
			return engine;
		}
		catch(Exception e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}
	
}
