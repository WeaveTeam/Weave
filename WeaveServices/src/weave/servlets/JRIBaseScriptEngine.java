package weave.servlets;

import java.io.IOException;
import java.io.Reader;
import java.io.StringWriter;
import java.io.Writer;

import javax.script.AbstractScriptEngine;
import javax.script.Bindings;
import javax.script.ScriptContext;
import javax.script.ScriptEngineFactory;
import javax.script.ScriptException;
import javax.script.SimpleBindings;

public abstract class JRIBaseScriptEngine
		extends AbstractScriptEngine 
		{

	private static final int WRITER_SIZE = 10000;

	private ScriptEngineFactory factory;

	
	public Object eval(Reader reader, ScriptContext context) throws ScriptException {
		Writer writer = new StringWriter(WRITER_SIZE);
		int c = 0;
		try {
			while((c = reader.read()) != -1) {
				writer.write(c);
			}
		}
		catch(IOException ioe) {
			throw new ScriptException(ioe);
		}
		String script = writer.toString();
		return eval(script, context);
	}

	public Bindings createBindings() {
		return new SimpleBindings();
	}

	public ScriptEngineFactory getFactory() {
		return factory;
	}
	
	void setFactory(ScriptEngineFactory factory) {
		this.factory = factory;
	}



}
