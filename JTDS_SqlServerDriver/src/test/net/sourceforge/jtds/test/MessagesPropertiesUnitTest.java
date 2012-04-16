// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2005 The jTDS Project
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

import junit.framework.Test;
import junit.framework.TestSuite;
import net.sourceforge.jtds.jdbc.Messages;
import java.util.Enumeration;
import java.util.ResourceBundle;



/**
 * Unit tests for the <code>Messages.properties</code> file.
 *
 * @author David D. Kilzer
 * @version $Id: MessagesPropertiesUnitTest.java,v 1.3 2005-09-23 21:44:08 ddkilzer Exp $
 */
public class MessagesPropertiesUnitTest extends UnitTestBase {


    /**
     * Construct a test suite for this class.
     *
     * @return The test suite to run.
     */
    public static Test suite() {

        final TestSuite testSuite = new TestSuite(MessagesPropertiesUnitTest.class.getName());

        final ResourceBundle messages = (ResourceBundle) invokeStaticMethod(
                Messages.class, "loadResourceBundle", new Class[]{}, new Object[]{});
        final Enumeration keysEnumeration = messages.getKeys();

        while (keysEnumeration.hasMoreElements()) {
            String key = (String) keysEnumeration.nextElement();
            if (key.startsWith("prop.desc.")) {
                final String propertyName = key.substring("prop.desc.".length());
                testSuite.addTest(new TestDescriptionHasProperty(propertyName, messages));
            }
            else if (key.startsWith("prop.")) {
                final String propertyName = key.substring("prop.".length());
                testSuite.addTest(new TestPropertyHasDescription(propertyName, messages));
            }
        }

        return testSuite;
    }


    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public MessagesPropertiesUnitTest(final String name) {
        super(name);
    }



    /**
     * Tests that a given description key has a matching property key in
     * <code>Messages.properties</code>.
     */
    public static class TestDescriptionHasProperty extends UnitTestBase {

        private final ResourceBundle messages;
        private final String property;


        /**
         * Constructor.
         *
         * @param property The property name to test.
         * @param messages The resource bundle containing all of the messages.
         */
        public TestDescriptionHasProperty(String property, ResourceBundle messages) {
            super("testDescriptionHasProperty_" + property);
            this.property = property;
            this.messages = messages;
        }


        /**
         * Provides a null test suite so that JUnit will not try to instantiate this class directly.
         *
         * @return The test suite (always <code>null</code>).
         */
        public static final Test suite() {
            return null;
        }


        /**
         * Runs the test that a given description key has a matching property key in
         * <code>Messages.properties</code>.
         *
         * @throws Throwable on error.
         */
        protected void runTest() throws Throwable {
            String property = (String) messages.getObject("prop." + this.property);
            assertTrue(property.trim().length() > 0);
        }
    }



    /**
     * Tests that a given property key has a matching description key in
     * <code>Messages.properties</code>.
     */
    public static class TestPropertyHasDescription extends UnitTestBase {

        private final ResourceBundle messages;
        private final String property;


        /**
         * Constructor.
         *
         * @param property The property name to test.
         * @param messages The resource bundle containing all of the messages.
         */
        public TestPropertyHasDescription(String property, ResourceBundle messages) {
            super("testPropertyHasDescription_" + property);
            this.property = property;
            this.messages = messages;
        }


        /**
         * Provides a null test suite so that JUnit will not try to instantiate this class directly.
         *
         * @return The test suite (always <code>null</code>).
         */
        public static final Test suite() {
            return null;
        }


        /**
         * Runs the test that a given property key has a matching description key in
         * <code>Messages.properties</code>.
         *
         * @throws Throwable on error.
         */
        protected void runTest() throws Throwable {
            String description = (String) messages.getObject("prop.desc." + this.property);
            assertTrue(description.trim().length() > 0);
        }
    }
}
