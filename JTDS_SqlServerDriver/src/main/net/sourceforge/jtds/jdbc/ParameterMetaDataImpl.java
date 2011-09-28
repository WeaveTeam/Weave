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
package net.sourceforge.jtds.jdbc;

import java.sql.*;

/**
 * jTDS implementation of <code>ParameterMetaData</code>.
 * <p/>
 * For Sybase it is usually possible to obtain true parameter data for prepared
 * statements. For Microsoft just use information determined from the actual
 * parameters if set or return some reasonable defaults otherwise.
 *
 * @author Brian Heineman
 * @author Mike Hutchinson
 * @version $Id: ParameterMetaDataImpl.java,v 1.7.2.3 2009-12-30 08:45:34 ickzon Exp $
 */
public class ParameterMetaDataImpl implements ParameterMetaData {
    private final ParamInfo[] parameterList;
    private final int maxPrecision;
    private final boolean useLOBs;


    public ParameterMetaDataImpl(ParamInfo[] parameterList, ConnectionJDBC2 connection) {
        if (parameterList == null) {
            parameterList = new ParamInfo[0];
        }

        this.parameterList = parameterList;
        this.maxPrecision = connection.getMaxPrecision();
        this.useLOBs = connection.getUseLOBs();
    }

    public int getParameterCount() throws SQLException {
        return parameterList.length;
    }

    public int isNullable(int param) throws SQLException {
        return ParameterMetaData.parameterNullableUnknown;
    }

    public int getParameterType(int param) throws SQLException {
        if (useLOBs) {
            return getParameter(param).jdbcType;
        } else {
            return Support.convertLOBType(getParameter(param).jdbcType);
        }
    }

    public int getScale(int param) throws SQLException {
        ParamInfo pi = getParameter(param);

        return (pi.scale >= 0) ? pi.scale : 0;
    }

    public boolean isSigned(int param) throws SQLException {
        ParamInfo pi = getParameter(param);

        switch (pi.jdbcType) {
            case java.sql.Types.BIGINT:
            case java.sql.Types.DECIMAL:
            case java.sql.Types.DOUBLE:
            case java.sql.Types.FLOAT:
            case java.sql.Types.INTEGER:
            case java.sql.Types.SMALLINT:
            case java.sql.Types.REAL:
            case java.sql.Types.NUMERIC:
                return true;
            default:
                return false;
        }
    }

    public int getPrecision(int param) throws SQLException {
        ParamInfo pi = getParameter(param);

        return (pi.precision >= 0) ? pi.precision : maxPrecision;
    }

    public String getParameterTypeName(int param) throws SQLException {
        return getParameter(param).sqlType;
    }

    public String getParameterClassName(int param) throws SQLException {
        return Support.getClassName(getParameterType(param));
    }

    public int getParameterMode(int param) throws SQLException {
        ParamInfo pi = getParameter(param);

        if (pi.isOutput) {
             return pi.isSet ? parameterModeInOut : parameterModeOut;
        }

        return pi.isSet ? parameterModeIn : parameterModeUnknown;
    }

    private ParamInfo getParameter(int param) throws SQLException {
        if (param < 1 || param > parameterList.length) {
            throw new SQLException(
                    Messages.get("error.prepare.paramindex",
                                        Integer.toString(param)), "07009");
        }

        return parameterList[param - 1];
    }

    /////// JDBC4 demarcation, do NOT put any JDBC3 code below this line ///////

    /* (non-Javadoc)
     * @see java.sql.Wrapper#isWrapperFor(java.lang.Class)
     */
    public boolean isWrapperFor(Class arg0) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

    /* (non-Javadoc)
     * @see java.sql.Wrapper#unwrap(java.lang.Class)
     */
    public Object unwrap(Class arg0) throws SQLException {
        // TODO Auto-generated method stub
        throw new AbstractMethodError();
    }

}