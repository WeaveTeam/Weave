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
package org.oicweave.tests;

//package amfdemo;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;

import org.oicweave.beans.QueryParam;

import flex.messaging.io.SerializationContext;
import flex.messaging.io.amf.Amf3Input;
import flex.messaging.io.amf.Amf3Output;

public class AmfTest {
 
	public static void main(String[] args) {
		try {
		
			SerializationContext context = getSerializationContext();
			
/*			testBean.setByte(new Byte((byte) 9));
			testBean.setBigDecimal(new BigDecimal("9.9"));
			testBean.setBoolean(new Boolean("true"));
			testBean.setCharacter(new Character('c'));
			testBean.setCalendar(Calendar.getInstance());
			testBean.setDate(Calendar.getInstance().getTime());
			testBean.setDouble(new Double(999.9));
			testBean.setFloat(new Float(99.9f));
			testBean.setInteger(new Integer("999"));
			testBean.setList(new ArrayList());
			testBean.setLong(new Long(99999));
			testBean.setMap(new HashMap());
			testBean.setDocument(DocumentBuilderFactory.newInstance().newDocumentBuilder().newDocument());
			testBean.setShort(new Short("99"));
			testBean.setString("test");
*/			
			ByteArrayOutputStream bout = new ByteArrayOutputStream();
			Amf3Output amf3Output = new Amf3Output(context);
			amf3Output.setOutputStream(bout);
			amf3Output.writeObject(new QueryParam("a","b"));
			amf3Output.flush();
			amf3Output.close();
			 
			InputStream bIn = new ByteArrayInputStream(bout.toByteArray());
			Amf3Input amf3Input = new Amf3Input(context);
			amf3Input.setInputStream(bIn);
			/*			TestBean o = (TestBean) amf3Input.readObject();
			 
			System.out.println(o.getByte().equals(testBean.getByte()));
			System.out.println(o.getBigDecimal().equals(testBean.getBigDecimal()));
			System.out.println(o.getBoolean().equals(testBean.getBoolean()));
			System.out.println(o.getCharacter().equals(testBean.getCharacter()));
			System.out.println(o.getCalendar().equals(testBean.getCalendar()));
			System.out.println(o.getDate().equals(testBean.getDate()));
			System.out.println(o.getDouble().equals(testBean.getDouble()));
			System.out.println(o.getFloat().equals(testBean.getFloat()));
			System.out.println(o.getInteger().equals(testBean.getInteger()));
			System.out.println(o.getLong().equals(testBean.getLong()));
			System.out.println(o.getString().equals(testBean.getString()));
*/		 
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	 
	public static SerializationContext getSerializationContext() {
	
	//Threadlocal SerializationContent
	SerializationContext serializationContext = SerializationContext.getSerializationContext();
	serializationContext.enableSmallMessages = true;
	serializationContext.instantiateTypes = true;
	//use _remoteClass field
	serializationContext.supportRemoteClass = true;
	//false Legacy Flex 1.5 behavior was to return a java.util.Collection for Array
	//ture New Flex 2+ behavior is to return Object[] for AS3 Array
	serializationContext.legacyCollection = false;
	
	serializationContext.legacyMap = false;
	//false Legacy flash.xml.XMLDocument Type
	//true New E4X XML Type
	serializationContext.legacyXMLDocument = false;
	 
	//determines whether the constructed Document is name-space aware
	serializationContext.legacyXMLNamespaces = false;
	serializationContext.legacyThrowable = false;
	serializationContext.legacyBigNumbers = false;
	 
	serializationContext.restoreReferences = false;
	serializationContext.logPropertyErrors = false;
	serializationContext.ignorePropertyErrors = true;
	return serializationContext;
	
	/*
	  serializationContext.enableSmallMessages = serialization.getPropertyAsBoolean(ENABLE_SMALL_MESSAGES, true);
	  serializationContext.instantiateTypes = serialization.getPropertyAsBoolean(INSTANTIATE_TYPES, true);
	  serializationContext.supportRemoteClass = serialization.getPropertyAsBoolean(SUPPORT_REMOTE_CLASS, false);
	  serializationContext.legacyCollection = serialization.getPropertyAsBoolean(LEGACY_COLLECTION, false);
	  serializationContext.legacyMap = serialization.getPropertyAsBoolean(LEGACY_MAP, false);
	  serializationContext.legacyXMLDocument = serialization.getPropertyAsBoolean(LEGACY_XML, false);
	  serializationContext.legacyXMLNamespaces = serialization.getPropertyAsBoolean(LEGACY_XML_NAMESPACES, false);
	  serializationContext.legacyThrowable = serialization.getPropertyAsBoolean(LEGACY_THROWABLE, false);
	  serializationContext.legacyBigNumbers = serialization.getPropertyAsBoolean(LEGACY_BIG_NUMBERS, false);
	  boolean showStacktraces = serialization.getPropertyAsBoolean(SHOW_STACKTRACES, false);
	  if (showStacktraces && Log.isWarn())
	  log.warn("The " + SHOW_STACKTRACES + " configuration option is deprecated and non-functional. Please remove this from your configuration file.");
	  serializationContext.restoreReferences = serialization.getPropertyAsBoolean(RESTORE_REFERENCES, false);
	  serializationContext.logPropertyErrors = serialization.getPropertyAsBoolean(LOG_PROPERTY_ERRORS, false);
	  serializationContext.ignorePropertyErrors = serialization.getPropertyAsBoolean(IGNORE_PROPERTY_ERRORS, true);
	  */
	}
}