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

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import java.util.zip.DeflaterOutputStream;

import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.io.IOUtils;

import weave.beans.JsonRpcErrorModel;
import weave.beans.JsonRpcRequestModel;
import weave.utils.CSVParser;
import weave.utils.ListUtils;

import com.google.gson.Gson;
import com.heatonresearch.httprecipes.html.PeekableInputStream;
import com.thoughtworks.paranamer.BytecodeReadingParanamer;
import com.thoughtworks.paranamer.Paranamer;

import flex.messaging.MessageException;
import flex.messaging.io.SerializationContext;
import flex.messaging.io.amf.ASObject;
import flex.messaging.io.amf.Amf3Input;
import flex.messaging.io.amf.Amf3Output;
import flex.messaging.messages.ErrorMessage;

/**
 * This class provides a servlet interface to a set of functions.
 * The functions may be invoked using URL parameters via HTTP GET or AMF3-serialized objects via HTTP POST.
 * Currently, the result of calling a function is given as an AMF3-serialized object.
 * 
 * TODO: Provide optional JSON output.
 * 
 * Not all objects will be supported automatically.
 * GenericServlet supports basic AMF3-serialized objects such as String,Object,Array.
 * 
 * The following mappings work (ActionScript -> Java):
 * Array -> Object[], Object[][], String[], String[][], double[], double[][], List
 * Object -> Map<String,Object>
 * String -> String, int, Integer, boolean, Boolean
 * Boolean -> boolean, Boolean
 * Number -> double
 * Raw byte stream -> Java InputStream
 * 
 * The following Java parameter types are supported:
 * boolean, Boolean
 * int, Integer
 * float, Float
 * double, Double
 * String, String[], String[][]
 * Object, Object[], Object[][]
 * double[], double[][]
 * Map<String,Object>
 * List
 * InputStream
 * 
 * TODO: Add support for more common parameter types.
 * 
 * @author skota
 * @author adufilie
 */

public class GenericServlet extends HttpServlet
{
	private static final long serialVersionUID = 1L;
	public static long debugThreshold = 1000;
	
	/**
	 * This is the name of the URL parameter corresponding to the method name.
	 */
	protected final String METHOD = "method";
	protected final String PARAMS = "params";
	protected final String STREAM_PARAMETER_INDEX = "streamParameterIndex";
	
	private Map<String, ExposedMethod> methodMap = new HashMap<String, ExposedMethod>(); //Key: methodName
    private Paranamer paranamer = new BytecodeReadingParanamer(); // this gets parameter names from Methods
    
    /**
     * This class contains a Method with its parameter names and class instance.
     */
	private class ExposedMethod
	{
		public ExposedMethod(Object instance, Method method, String[] paramNames)
		{
			this.instance = instance;
			this.method = method;
			this.paramNames = paramNames;
		}
		public Object instance;
		public Method method;
		public String[] paramNames;
	}
	
	/**
	 * Default constructor.
	 * This initializes all public methods defined in a class extending GenericServlet.
	 */
	protected GenericServlet()
	{
		super();
		initLocalMethods();
	}
	
	/**
	 * @param serviceObjects The objects to invoke methods on.
	 */
	protected GenericServlet(Object ...serviceObjects)
	{
	    super();
	    initLocalMethods();
	    for (Object serviceObject : serviceObjects)
	    	initAllMethods(serviceObject);
	}
	
	/**
	 * This function will expose all the public methods of a class as servlet methods.
	 * @param serviceObject The object containing public methods to be exposed by the servlet.
	 */
	protected void initLocalMethods()
	{
		initAllMethods(this);
	}
	
	/**
	 * This function will expose all the declared public methods of a class as servlet methods,
	 * except methods that match those declared by GenericServlet or a superclass of GenericServlet.
	 * @param serviceObject The object containing public methods to be exposed by the servlet.
	 */
	protected void initAllMethods(Object serviceObject)
	{
		Method[] genericServletMethods = GenericServlet.class.getMethods();
		Method[] declaredMethods = serviceObject.getClass().getDeclaredMethods();
		for (int i = declaredMethods.length - 1; i >= 0; i--)
		{
			Method declaredMethod = declaredMethods[i];
			boolean shouldIgnore = false;
			for (Method genericServletMethod : genericServletMethods)
			{
				if (declaredMethod.getName().equals(genericServletMethod.getName()) &&
					Arrays.equals(declaredMethod.getParameterTypes(), genericServletMethod.getParameterTypes()) )
				{
					shouldIgnore = true;
					break;
				}
			}
			if (!shouldIgnore)
				initMethod(serviceObject, declaredMethod);
		}
		
		// for debugging
		printExposedMethods();
	}
    
    /**
     * @param serviceObject The instance of an object to use in the servlet.
     * @param methodName The method to expose on serviceObject.
     */
    synchronized protected void initMethod(Object serviceObject, Method method)
    {
    	// only expose public methods
    	if (!Modifier.isPublic(method.getModifiers()))
    		return;
		String methodName = method.getName();
		if (methodMap.containsKey(methodName))
    	{
			methodMap.put(methodName, null);

			System.err.println(String.format(
    				"Method %s.%s will not be supported because there are multiple definitions.",
    				this.getClass().getName(), methodName
    			));
    	}
		else
		{
			String[] paramNames = null;
			paramNames = paranamer.lookupParameterNames(method, false); // returns null if not found
			
			methodMap.put(methodName, new ExposedMethod(serviceObject, method, paramNames));
		}
    }
    
    protected void printExposedMethods()
    {
    	String output = "";
    	List<String> methodNames = new Vector<String>(methodMap.keySet());
    	Collections.sort(methodNames);
    	for (String methodName : methodNames)
    	{
    		ExposedMethod m = methodMap.get(methodName);
    		if (m != null)
    			output += String.format(
	    				"Exposed servlet method: %s.%s\n",
	    				m.instance.getClass().getName(),
	    				formatFunctionSignature(
	    						m.method.getName(),
	    						m.method.getParameterTypes(),
	    						m.paramNames
	    					)
	    			);
    		else
    			output += "Not exposed: "+methodName;
    	}
    	System.out.print(output);
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
    	handleServletRequest(request, response);
    }
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
    	handleServletRequest(request, response);
    }
    
    protected class ServletRequestInfo
    {
    	public ServletRequestInfo(HttpServletRequest request, HttpServletResponse response, JsonRpcRequestModel jsonObj)
    	{
    		this.request = request;
    		this.response = response;
    		this.jsonObj = jsonObj;
    	}
    	
    	HttpServletRequest request;
    	HttpServletResponse response;
    	JsonRpcRequestModel jsonObj;
    }
    
    /**
     * This maps a thread to the corresponding RequestInfo for the doGet() or doPost() call that thread is handling.
     */
    private Map<Thread,ServletRequestInfo> servletRequestInfo = new HashMap<Thread,ServletRequestInfo>();
    
    /**
     * This function retrieves the HttpServletResponse associated with the current thread's doGet() or doPost() call.
     * In a public function with a void return type, you can use the ServletOutputStream for full control over the output.
     */
    protected ServletRequestInfo getServletRequestInfo()
    {
    	synchronized (servletRequestInfo)
    	{
    		return servletRequestInfo.get(Thread.currentThread());
    	}
    }
    
    private void setServletRequestInfo(HttpServletRequest request, HttpServletResponse response, JsonRpcRequestModel jsonObj)
    {
    	synchronized (servletRequestInfo)
    	{
    		servletRequestInfo.put(Thread.currentThread(), new ServletRequestInfo(request, response, jsonObj));
    	}
    }
    
    private void handleServletRequest(HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException
    {
		Gson gson = new Gson(); 
    	try
    	{
    		if (request.getMethod().equals("GET"))
    		{
        		List<String> urlParamNames = Collections.list(request.getParameterNames());
        		
    			HashMap<String, String> params = new HashMap<String,String>();
    			
    			for (String paramName : urlParamNames)
    				params.put(paramName, request.getParameter(paramName));
    			JsonRpcRequestModel jsonObj = new JsonRpcRequestModel();
    			jsonObj.id = null;
    			jsonObj.method = params.remove(METHOD);
    			jsonObj.params = params;
    			
    			setServletRequestInfo(request, response, jsonObj);
    			
    			invokeMethod(jsonObj.method, params);
    		}
    		else if (request.getMethod().equals("POST"))
    		{
	    		try
	    		{
	    			String methodName;
	    			Object methodParams;
	    			Number streamParameterIndex = null;
	    			
	    			PeekableInputStream inputStream = new PeekableInputStream(request.getInputStream());
	    			if (inputStream.peek() == '{') // json
	    			{
	    				String streamString  = IOUtils.toString(inputStream, "UTF-8");
	    				JsonRpcRequestModel json = gson.fromJson(streamString, JsonRpcRequestModel.class);
	    				methodName = json.method;
	    				methodParams = json.params;
	    				
	    				setServletRequestInfo(request, response, json);
	    			}
	    			else // AMF3
	    			{
	    				ASObject obj = (ASObject)deseriaizeAmf3(inputStream);
	    				methodName = (String) obj.get(METHOD);
	    				methodParams = obj.get(PARAMS);
	    				streamParameterIndex = (Number) obj.get(STREAM_PARAMETER_INDEX);
	    				
	    				setServletRequestInfo(request, response, null);
	    			}
	    			
	    			if (methodParams instanceof List<?>)
	    				methodParams = ((List<?>)methodParams).toArray();
	    			
	    			if (methodParams instanceof Object[]) // Array of parameters
	    			{
	    				if (streamParameterIndex != null)
	    				{
		    				int index = streamParameterIndex.intValue();
		    				if (index >= 0)
		    					((Object[])methodParams)[index] = inputStream;
	    				}
	    				
	    				invokeMethod(methodName, (Object[])methodParams);
	    			}
	    			else // Map of parameters
	    			{
	    				invokeMethod(methodName, (Map<?,?>)methodParams);
	    			}
		    	}
	    		catch (IOException e)
	    		{
	    			sendError(response, e);
	    		}
		    	catch (Exception e)
		    	{
		    		sendError(response, e);
		    	}
    		}
    		else
    		{
    			throw new ServletException("HTTP Request method not supported: " + request.getMethod());
    		}
    	}
    	finally
    	{
    		synchronized (servletRequestInfo)
    		{
    			servletRequestInfo.remove(Thread.currentThread());
    		}
    	}
	}
	
	@SuppressWarnings({ "unchecked", "rawtypes" })
	private void invokeMethod(String methodName, Map params) throws IOException
	{	
		if(!methodMap.containsKey(methodName) || methodMap.get(methodName) == null)
		{
			HttpServletResponse response = getServletRequestInfo().response;
			sendError(response, new IllegalArgumentException(String.format("Method \"%s\" not supported.", methodName)));
			return;
		}
		ExposedMethod exposedMethod = methodMap.get(methodName);
		String[] argNames = exposedMethod.paramNames;
		Class[] argTypes = exposedMethod.method.getParameterTypes();
		Object[] argValues = new Object[argTypes.length];
		
		Map extraParameters = null; // parameters that weren't mapped directly to method arguments
		
		// For each method parameter, get the corresponding url parameter value.
		if (argNames != null && params != null)
		{
			//TODO: check why params is null
			for (Object parameterName : params.keySet())
			{
				Object parameterValue = params.get(parameterName);
				int index = ListUtils.findString((String)parameterName, argNames);
				if (index >= 0)
				{
					argValues[index] = parameterValue;
				}
				else if (!parameterName.equals(METHOD))
				{
					if (extraParameters == null)
						extraParameters = new HashMap();
					extraParameters.put(parameterName, parameterValue);
				}
			}
		}
		
		// support for a function having a single Map<String,String> parameter
		// see if we can find a Map arg.  If so, set it to extraParameters
		if (argTypes != null)
		{
			for (int i = 0; i < argTypes.length; i++)
			{
				if (argTypes[i] == Map.class)
				{
					// avoid passing a null Map to the function
					if (extraParameters == null)
						extraParameters = new HashMap<String,String>();
					argValues[i] = extraParameters;
					extraParameters = null;
					break;
				}
			}
		}
		if (extraParameters != null)
		{
			System.out.println("Received servlet request: " + methodName + Arrays.deepToString(argValues));
			System.out.println("Unused parameters: "+extraParameters.entrySet());
		}
		
		invokeMethod(methodName, argValues);
	}
	
	@SuppressWarnings({ "unchecked", "rawtypes" })
	protected Object cast(Object value, Class<?> type)
	{
		// if given value is a String, check if the function is expecting a different type
		if (value instanceof String)
		{
			try
			{
				if (type == int.class || type == Integer.class)
				{
					value = Integer.parseInt((String)value);
				}
				else if (type == float.class || type == Float.class)
				{
					value = Float.parseFloat((String)value);
				}
				else if (type == double.class || type == Double.class)
				{
					value = Double.parseDouble((String)value);
				}
				else if (type == boolean.class || type == Boolean.class)
				{
					value = ((String)(value)).equalsIgnoreCase("true");
				}
				else if (type == String[].class || type == List.class)
				{
					String[][] table = CSVParser.defaultParser.parseCSV((String)value, true);
					if (table.length == 0)
						value = new String[0]; // empty
					else
						value = table[0]; // first row
					
					if (type == List.class)
						value = Arrays.asList((String[])value);
				}
				else if(type == InputStream.class)
				{
					try
					{
						String temp = (String) value;
						value = (InputStream)new ByteArrayInputStream(temp.getBytes("UTF-8"));
					}catch (Exception e) {
						
						return null;
					}
				}
			}
			catch (NumberFormatException e)
			{
				// if number parsing fails, leave the original value untouched
			}
		}
		else if (value == null)
		{
			if (type == double.class || type == Double.class)
				value = Double.NaN;
			else if (type == float.class || type == Float.class)
				value = Float.NaN;
		}
		else
		{
			// additional parameter type casting
			if (value instanceof Boolean && type == boolean.class)
			{
				value = (boolean)(Boolean)value;
			}
			else if (value.getClass() == Object[].class)
			{
				Object[] valueArray = (Object[])value;
				if (type == List.class)
				{
					value = ListUtils.copyArrayToList(valueArray, new Vector());
				}
				else if (type == Object[][].class)
				{
					Object[][] valueMatrix = new Object[valueArray.length][];
					for (int i = 0; i < valueArray.length; i++)
					{
						valueMatrix[i] = (Object[])valueArray[i];
					}
					value = valueMatrix;
				}
				else if (type == String[][].class)
				{
					String[][] valueMatrix = new String[valueArray.length][];
					for (int i = 0; i < valueArray.length; i++)
					{
						// cast Objects to Strings
						Object[] objectArray = (Object[])valueArray[i];
						valueMatrix[i] = ListUtils.copyStringArray(objectArray, new String[objectArray.length]);
					}
					value = valueMatrix;
				}
				else if (type == String[].class)
				{
					value = ListUtils.copyStringArray(valueArray, new String[valueArray.length]);
				}
				else if (type == double[][].class)
				{
					double[][] valueMatrix = new double[valueArray.length][];
					for (int i = 0; i < valueArray.length; i++)
					{
						// cast Objects to doubles
						Object[] objectArray = (Object[])valueArray[i];
						valueMatrix[i] = ListUtils.copyDoubleArray(objectArray, new double[objectArray.length]);
					}
					value = valueMatrix;
				}
				else if (type == double[].class)
				{
					value = ListUtils.copyDoubleArray(valueArray, new double[valueArray.length]);
				}
				else if (type == int[][].class)
				{
					int[][] valueMatrix = new int[valueArray.length][];
					for (int i = 0; i < valueArray.length; i++)
					{
						// cast Objects to doubles
						Object[] objectArray = (Object[])valueArray[i];
						valueMatrix[i] = ListUtils.copyIntegerArray(objectArray, new int[objectArray.length]);
					}
					value = valueMatrix;
				}
				else if (type == int[].class)
				{
					value = ListUtils.copyIntegerArray(valueArray, new int[valueArray.length]);
				}
			}
			else if ((type == int.class || type == Integer.class) && value instanceof Number)
			{
				value = ((Number)value).intValue();
			}
			else if ((type == Double.class || type == double.class) && value instanceof Number)
			{
				value = ((Number)value).doubleValue();
			}
			else if ((type == float.class || type== Float.class) && value instanceof Number)
			{
				value = ((Number)value).floatValue();
			}
			
		}
		return value;
	}
	
	/**
	 * @param methodName The name of the function to invoke.
	 * @param methodParameters A list of input parameters for the method.  Values will be cast to the appropriate types if necessary.
	 */
	@SuppressWarnings("rawtypes")
	private void invokeMethod(String methodName, Object[] methodParameters) throws IOException
	{
		HttpServletResponse response = getServletRequestInfo().response;
		
		// get method by name
		ExposedMethod exposedMethod = methodMap.get(methodName);
		if (exposedMethod == null)
		{
			sendError(response, new IllegalArgumentException("Unknown method: "+methodName));
		}
		
		// cast input values to appropriate types if necessary
		Class[] expectedArgTypes = exposedMethod.method.getParameterTypes();
		if (expectedArgTypes.length == methodParameters.length)
		{
	    	for (int index = 0; index < methodParameters.length; index++)
	    	{
				methodParameters[index] = cast(methodParameters[index], expectedArgTypes[index]);
			}
    	}

    	// prepare to output the result of the method call
    	ServletOutputStream servletOutputStream = response.getOutputStream();
		long startTime = System.currentTimeMillis();
    	
		// Invoke the method on the object with the arguments 
		try
		{
			Object result = exposedMethod.method.invoke(exposedMethod.instance, methodParameters);
			
			if(getServletRequestInfo().jsonObj != null)
			{
				Gson gson = new Gson();
				String jsonResult = gson.toJson(result);
				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.setHeader("jsonrpc", "2.0");
				response.setHeader("result", jsonResult);
				String id = getServletRequestInfo().request.getHeader("id");
				if(id==null)
					id = "null";
				response.setHeader("id", id);
			}
			else if (exposedMethod.method.getReturnType() != void.class)
			{
				seriaizeCompressedAmf3(result, servletOutputStream);
			}
		}
		catch (InvocationTargetException e)
		{
			System.err.println(methodName + Arrays.deepToString(methodParameters));
			sendError(response, e.getCause());
		}
		catch (IllegalArgumentException e)
		{
			String moreInfo = 
				"Expected: " + formatFunctionSignature(methodName, expectedArgTypes, exposedMethod.paramNames) + "\n" +
				"Received: " + formatFunctionSignature(methodName, methodParameters, null);
			
			sendError(response, e, moreInfo);
		}
		catch (Exception e)
		{
			System.err.println(methodName + Arrays.deepToString(methodParameters));
			sendError(response, e);
		}
		
		long endTime = System.currentTimeMillis();
		// debug
		if (endTime - startTime >= debugThreshold)
			System.out.println(String.format("[%sms] %s", endTime - startTime, methodName + Arrays.deepToString(methodParameters)));
    }
    
    /**
     * This function formats a Java function signature as a String.
     * @param methodName The name of the method.
     * @param paramValuesOrTypes A list of Class objects or arbitrary Objects to get the class names from.
     * @param paramNames The names of the parameters, may be null.
     * @return A readable Java function signature.
     */
    private String formatFunctionSignature(String methodName, Object[] paramValuesOrTypes, String[] paramNames)
    {
    	// don't use paramNames if the length doesn't match the paramValuesOrTypes length.
    	if (paramNames != null && paramNames.length != paramValuesOrTypes.length)
    		paramNames = null;
    	
    	List<String> names = new Vector<String>(paramValuesOrTypes.length);
    	for (int i = 0; i < paramValuesOrTypes.length; i++)
    	{
    		Object valueOrType = paramValuesOrTypes[i];
    		String name = "null";
    		if (valueOrType instanceof Class)
    			name = ((Class<?>)valueOrType).getName();
    		else if (valueOrType != null)
    			name = valueOrType.getClass().getName();
    		
    		// decode output of Class.getName()
    		while (name.charAt(0) == '[') // array type
    		{
    			name = name.substring(1) + "[]";
    			// decode element type encoding
    			String type = "";
    			switch (name.charAt(0))
    			{
    				case 'Z': type = "boolean"; break;
    				case 'B': type = "byte"; break;
    				case 'C': type = "char"; break;
    				case 'D': type = "double"; break;
    				case 'F': type = "float"; break;
    				case 'I': type = "int"; break;
    				case 'J': type = "long"; break;
    				case 'S': type = "short"; break;
    				case 'L':
    					// remove ';'
    					name = name.replace(";", "");
    					break;
    				default: continue;
    			}
    			// remove first char encoding
    			name = type + name.substring(1);
    		}
			// hide package names
			if (name.indexOf('.') >= 0)
				name = name.substring(name.lastIndexOf('.') + 1);
    		
			if (paramNames != null)
				name += " " + paramNames[i];
			
    		names.add(name);
    	}
    	String result = names.toString();
    	return String.format("%s(%s)", methodName, result.substring(1, result.length() - 1));
    }
    
    private void sendError(HttpServletResponse response, Throwable exception) throws IOException
    {
    	sendError(response, exception, null);
    }
    private void sendError(HttpServletResponse response, Throwable exception, String moreInfo) throws IOException
	{
    	//response.setHeader("Cache-Control", "no-cache");
    	//response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, message);
    	
    	String message;
    	if (exception instanceof RuntimeException)
    		message = exception.toString();
    	else
    		message = exception.getMessage();
    	if (moreInfo != null)
    		message += "\n" + moreInfo;
    	
    	// log errors
    	exception.printStackTrace();
    	System.err.println("Serializing ErrorMessage: "+message);
    	
    	if(getServletRequestInfo().jsonObj !=null)
    	{
    		JsonRpcErrorModel jsonErrorObject = new JsonRpcErrorModel();
    		String methodName = getServletRequestInfo().jsonObj.method;
    		if(!methodMap.containsKey(methodName) || methodMap.get(methodName) == null)
    		{
    			jsonErrorObject.code = "-32601";
    			jsonErrorObject.message = "Method not found";
    			jsonErrorObject.data = message;
    		}
    		else if(exception instanceof IllegalArgumentException)
    		{
    			jsonErrorObject.code = "-32602";
    			jsonErrorObject.message = "Invalid params";
    			jsonErrorObject.data = message;
    		}
    		else //TODO: Add more error messages based on exception type
    		{
    			jsonErrorObject.code = "-32603";
    			jsonErrorObject.message = "Internal error";
    			jsonErrorObject.data = message;
    		}
    		Gson gson = new Gson();
			response.setContentType("application/json");
			response.setCharacterEncoding("UTF-8");
			response.setHeader("jsonrpc", "2.0");
			response.setHeader("error", gson.toJson(jsonErrorObject));
			String id = getServletRequestInfo().request.getHeader("id");
			if (id == null)
				id = "null";
			response.setHeader("id", id);
    	}
    	else
    	{
    		ServletOutputStream servletOutputStream = response.getOutputStream();
        	ErrorMessage errorMessage = new ErrorMessage(new MessageException(message));
        	errorMessage.faultCode = exception.getClass().getSimpleName();
        	seriaizeCompressedAmf3(errorMessage, servletOutputStream);	
    	}
	}
    
    protected static SerializationContext getSerializationContext()
    {
    	SerializationContext context = SerializationContext.getSerializationContext();
    	
    	// set serialization context properties
    	context.enableSmallMessages = true;
    	context.instantiateTypes = true;
       	context.supportRemoteClass = true;
    	context.legacyCollection = false;
    	context.legacyMap = false;
    	context.legacyXMLDocument = false;
    	context.legacyXMLNamespaces = false;
    	context.legacyThrowable = false;
    	context.legacyBigNumbers = false;
    	context.restoreReferences = false;
    	context.logPropertyErrors = false;
    	context.ignorePropertyErrors = true;
    	
    	return context;
    }
    
    // Serialize a Java Object to AMF3 ByteArray
    protected void seriaizeCompressedAmf3(Object objToSerialize, ServletOutputStream servletOutputStream)
    {
    	try
    	{
    		SerializationContext context = getSerializationContext();

    		DeflaterOutputStream deflaterOutputStream = new DeflaterOutputStream(servletOutputStream);
    		
			Amf3Output amf3Output = new Amf3Output(context);
			amf3Output.setOutputStream(deflaterOutputStream); // compress
			amf3Output.writeObject(objToSerialize);
			amf3Output.flush();
			
			deflaterOutputStream.close(); // this is necessary to finish the compression
			
			//amf3Output.close(); //not closing output stream -- see http://viveklakhanpal.wordpress.com/2010/07/01/error-2032ioerror/
    	}
    	catch (Exception e)
    	{
    		e.printStackTrace();
    	}
    }

    //  De-serialize a ByteArray/AMF3/Flex object to a Java object  
    protected ASObject deseriaizeAmf3(InputStream inputStream) throws ClassNotFoundException, IOException
    {
    	ASObject deSerializedObj = null;

    	SerializationContext context = getSerializationContext();
		
    	Amf3Input amf3Input = new Amf3Input(context);
		amf3Input.setInputStream(inputStream); // uncompress
		deSerializedObj = (ASObject) amf3Input.readObject();
		//amf3Input.close();
    	
		return deSerializedObj;
    }    
}
