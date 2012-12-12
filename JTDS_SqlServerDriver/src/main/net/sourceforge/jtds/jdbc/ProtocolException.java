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

/**
 * Exception class used to report errors in the TDS protocol.
 *
 * @author Mike Hutchinson
 * @version $Id: ProtocolException.java,v 1.3 2005-04-20 16:49:23 alin_sinpalean Exp $
 */
public class ProtocolException extends Exception {
    /**
     * Construct a ProtocolException with message.
     *
     * @param message The explanatory message.
     */
    public ProtocolException(String message) {
        super(message);
    }
}
