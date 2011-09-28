// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2004 The jTDS Project
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//
package net.sourceforge.jtds.test;

import java.util.Properties;



/**
 * Abstract class used to test the default properties set on a variety of methods.
 * <p/>
 * Implements the Command pattern.
 * 
 * @author David D. Kilzer
 * @version $Id: DefaultPropertiesTester.java,v 1.3 2004-08-24 17:45:07 bheineman Exp $
 */
public abstract class DefaultPropertiesTester {


    /**
     * Asserts that a default property is set properly.
     * 
     * @param message The message to display if the default property is not set.
     * @param url The JDBC url.
     * @param properties The initial properties set before testing the method.
     * @param fieldName The field name of the object if using reflection.
     * @param key The message key used to obtain the property name.
     * @param expected The expected value.
     */
    public abstract void assertDefaultProperty(
            String message, String url, Properties properties, String fieldName, String key, String expected);

}
