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

import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Field;

import junit.framework.Assert;
import junit.framework.TestCase;

import net.sourceforge.jtds.jdbc.Support;


/**
 * Base class for unit tests which do not connect to a database.
 *
 * @author David D. Kilzer
 * @version $Id: UnitTestBase.java,v 1.12 2005-12-22 17:24:07 ddkilzer Exp $
 */
public abstract class UnitTestBase extends TestCase {

    /**
     * Constructor.
     *
     * @param name The name of the test.
     */
    public UnitTestBase(final String name) {
        super(name);
    }


    /**
     * Invoke a constructor on a class using reflection.
     *
     * @param klass The class.
     * @param classes The classes in the parameter list.
     * @param objects The objects to be used as parameters.
     * @return The object constructed.
     */
    public static Object invokeConstructor(final Class klass, final Class[] classes, final Object[] objects) {
        try {
            Constructor constructor;
            try {
                constructor = klass.getDeclaredConstructor(classes);
            }
            catch (NoSuchMethodException e) {
                constructor = klass.getConstructor(classes);
            }
            constructor.setAccessible(true);
            return constructor.newInstance(objects);
        }
        catch (NoSuchMethodException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (InstantiationException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (IllegalAccessException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (InvocationTargetException e) {
            RuntimeException runtimeException = new RuntimeException(e.getTargetException().getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
    }


    /**
     * Get the value of an instance field on an object using reflection.
     *
     * @param instance The instance of the object.
     * @param fieldName The name of the field.
     * @return The object returned by getting the field.
     */
    public static Object invokeGetInstanceField(final Object instance, final String fieldName) {
        try {
            Field field;
            try {
                field = instance.getClass().getField(fieldName);
            }
            catch (NoSuchFieldException e) {
                field = instance.getClass().getDeclaredField(fieldName);
            }
            field.setAccessible(true);
            return field.get(instance);
        }
        catch (NoSuchFieldException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (IllegalAccessException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
    }


    /**
     * Set the value of an instance field on an object using reflection.
     *
     * @param instance The instance of the object.
     * @param fieldName The name of the field.
     * @param fieldValue The value to set the field to.
     */
    public static void invokeSetInstanceField(final Object instance, final String fieldName, final Object fieldValue) {
        try {
            Field field;
            try {
                field = instance.getClass().getField(fieldName);
            }
            catch (NoSuchFieldException e) {
                field = instance.getClass().getDeclaredField(fieldName);
            }
            field.setAccessible(true);
            field.set(instance, fieldValue);
        }
        catch (NoSuchFieldException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (IllegalAccessException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
    }


    /**
     * Invoke an instance method on an object using reflection.
     *
     * @param instance The instance of the object.
     * @param methodName The name of the method.
     * @param classes The classes in the parameter list.
     * @param objects The objects to be used as parameters.
     * @return The object returned by invoking the method.
     */
    public static Object invokeInstanceMethod(
            final Object instance, final String methodName, final Class[] classes, final Object[] objects) {

        try {
            Method method;
            try {
                method = instance.getClass().getDeclaredMethod(methodName, classes);
            }
            catch (NoSuchMethodException e) {
                method = instance.getClass().getMethod(methodName, classes);
            }
            method.setAccessible(true);
            return method.invoke(instance, objects);
        }
        catch (NoSuchMethodException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (IllegalAccessException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (InvocationTargetException e) {
            RuntimeException runtimeException = new RuntimeException(e.getTargetException().getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
    }


    /**
     * Invoke a static method on a class using reflection.
     *
     * @param klass The class.
     * @param methodName The name of the method.
     * @param classes The classes in the parameter list.
     * @param objects The objects to be used as parameters.
     * @return The object returned by invoking the method.
     */
    public static Object invokeStaticMethod(
            final Class klass, final String methodName, final Class[] classes, final Object[] objects) {

        try {
            Method method;
            try {
                method = klass.getDeclaredMethod(methodName, classes);
            }
            catch (NoSuchMethodException e) {
                method = klass.getMethod(methodName, classes);
            }
            method.setAccessible(true);
            return method.invoke(klass, objects);
        }
        catch (NoSuchMethodException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (IllegalAccessException e) {
            RuntimeException runtimeException = new RuntimeException(e.getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
        catch (InvocationTargetException e) {
            RuntimeException runtimeException = new RuntimeException(e.getTargetException().getMessage());
            Support.linkException(runtimeException, e);
            throw runtimeException;
        }
    }


    /**
     * Compare two arrays element-by-element.
     * <p/>
     * The default JUnit {@link Assert#assertEquals(String, Object, Object)} method
     * does not handle them properly.
     *
     * @param message The message to print upon failure.
     * @param expected The expected value.
     * @param actual The actual value.
     */
    protected void assertEquals(String message, Object[] expected, Object[] actual) {

        if (expected == null && actual == null) {
            return;
        }

        if (expected == null || actual == null) {
            failNotEquals(message, expected, actual);
        }

        if (expected.length != actual.length) {
            failNotEquals(message, expected, actual);
        }

        for (int i = 0; i < expected.length; i++) {
            if (expected[i] == null || !expected[i].equals(actual[i])) {
                failNotEquals(message, expected, actual);
            }
        }
    }


    /**
     * @see Assert#failNotEquals(java.lang.String, java.lang.Object, java.lang.Object)
     */
    private void failNotEquals(String message, Object[] expected, Object[] actual) {
        fail((String) invokeStaticMethod(Assert.class, "format",
                                         new Class[]{String.class, Object.class, Object.class},
                                         new Object[]{message, format(expected), format(actual)}));
    }


    /**
     * Format an <code>Object[]</code> object to a <code>String</code>.
     *
     * @param object The object to be formatted.
     * @return Formatted string representing the object.
     */
    private String format(Object[] object) {
        StringBuffer buf = new StringBuffer();
        if (object == null || object.length < 1) {
            buf.append(object);
        } else {
            buf.append('{');
            buf.append(object[0]);
            for (int i = 1; i < object.length; i++) {
                buf.append(',');
                if (object[i] instanceof Object[]) {
                    buf.append(format((Object[]) object[i]));
                }
                else {
                    buf.append(object[i]);
                }
            }
            buf.append('}');
        }
        return buf.toString();
    }


    /**
     * Changes the first character of a string to uppercase.
     *
     * @param s The string to be processed.
     * @return The value of <code>s</code> if it is <code>null</code> or zero length,
     *         else the string with the first character changed to uppercase.
     */
    protected static String ucFirst(String s) {
        if (s == null || s.length() == 0) return s;
        if (s.length() == 1) {
            return s.toUpperCase();
        }
        return s.substring(0, 1).toUpperCase() + s.substring(1);
    }

}
