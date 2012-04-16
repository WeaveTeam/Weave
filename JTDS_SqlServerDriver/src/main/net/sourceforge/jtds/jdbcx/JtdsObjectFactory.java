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
package net.sourceforge.jtds.jdbcx;

import java.util.Hashtable;
import javax.naming.Context;
import javax.naming.Name;
import javax.naming.Reference;
import javax.naming.spi.ObjectFactory;

import net.sourceforge.jtds.jdbc.Driver;
import net.sourceforge.jtds.jdbc.Messages;

/**
 * Description
 *
 * @author Alin Sinplean
 * @since 0.3
 * @version $Id: JtdsObjectFactory.java,v 1.25.2.1 2009-08-07 14:02:11 ickzon Exp $
 */
public class JtdsObjectFactory implements ObjectFactory {
    public Object getObjectInstance(Object refObj,
                                    Name name,
                                    Context nameCtx,
                                    Hashtable env)
    throws Exception {
        Reference ref = (Reference) refObj;

        if (ref.getClassName().equals(JtdsDataSource.class.getName())) {
            JtdsDataSource ds = new JtdsDataSource();

            ds.setServerName((String) ref.get(Messages.get(Driver.SERVERNAME)).getContent());
            final Object portNumber = ref.get(Messages.get(Driver.PORTNUMBER)).getContent();
            if (portNumber != null) {
                ds.setPortNumber(Integer.parseInt((String) portNumber));
            }
            ds.setDatabaseName((String) ref.get(Messages.get(Driver.DATABASENAME)).getContent());
            ds.setUser((String) ref.get(Messages.get(Driver.USER)).getContent());
            ds.setPassword((String) ref.get(Messages.get(Driver.PASSWORD)).getContent());
            ds.setCharset((String) ref.get(Messages.get(Driver.CHARSET)).getContent());
            ds.setLanguage((String) ref.get(Messages.get(Driver.LANGUAGE)).getContent());
            ds.setTds((String) ref.get(Messages.get(Driver.TDS)).getContent());
            ds.setBindAddress((String) ref.get(Messages.get(Driver.BINDADDRESS)).getContent());
            final Object serverType = ref.get(Messages.get(Driver.SERVERTYPE)).getContent();
            if (serverType != null) {
                ds.setServerType(Integer.parseInt((String) serverType));
            }
            ds.setDomain((String) ref.get(Messages.get(Driver.DOMAIN)).getContent());
            ds.setUseNTLMV2((String) ref.get(Messages.get(Driver.USENTLMV2)).getContent());
            ds.setInstance((String) ref.get(Messages.get(Driver.INSTANCE)).getContent());
            final Object lastUpdateCount = ref.get(Messages.get(Driver.LASTUPDATECOUNT)).getContent();
            if (lastUpdateCount != null) {
                ds.setLastUpdateCount("true".equals(lastUpdateCount));
            }
            final Object sendStringParametersAsUnicode =
                    ref.get(Messages.get(Driver.SENDSTRINGPARAMETERSASUNICODE)).getContent();
            if (sendStringParametersAsUnicode != null) {
                ds.setSendStringParametersAsUnicode("true".equals(sendStringParametersAsUnicode));
            }
            final Object namedPipe = ref.get(Messages.get(Driver.NAMEDPIPE)).getContent();
            if (namedPipe != null) {
                ds.setNamedPipe("true".equals(namedPipe));
            }
            ds.setMacAddress((String) ref.get(Messages.get(Driver.MACADDRESS)).getContent());
            final Object maxStatements = ref.get(Messages.get(Driver.MAXSTATEMENTS)).getContent();
            if (maxStatements != null) {
                ds.setMaxStatements(Integer.parseInt((String) maxStatements));
            }
            final Object packetSize = ref.get(Messages.get(Driver.PACKETSIZE)).getContent();
            if (packetSize != null) {
                ds.setPacketSize(Integer.parseInt((String) packetSize));
            }
            final Object prepareSql = ref.get(Messages.get(Driver.PREPARESQL)).getContent();
            if (prepareSql != null) {
                ds.setPrepareSql(Integer.parseInt((String) prepareSql));
            }
            final Object lobBuffer = ref.get(Messages.get(Driver.LOBBUFFER)).getContent();
            if (lobBuffer != null) {
                ds.setLobBuffer(Long.parseLong((String) lobBuffer));
            }
            final Object loginTimeout = ref.get(Messages.get(Driver.LOGINTIMEOUT)).getContent();
            if (loginTimeout != null) {
                ds.setLoginTimeout(Integer.parseInt((String) loginTimeout));
            }
            final Object socketTimeout = ref.get(Messages.get(Driver.SOTIMEOUT)).getContent();
            if (socketTimeout != null) {
                ds.setSocketTimeout(Integer.parseInt((String) socketTimeout));
            }
            final Object socketKeepAlive = ref.get(Messages.get(Driver.SOKEEPALIVE)).getContent();
            if (socketKeepAlive != null) {
                ds.setSocketKeepAlive("true".equalsIgnoreCase((String) socketKeepAlive));
            }
            final Object processId = ref.get(Messages.get(Driver.PROCESSID)).getContent();
            if (processId != null) {
                ds.setProcessId((String) processId);
            }
            ds.setAppName((String) ref.get(Messages.get(Driver.APPNAME)).getContent());
            ds.setProgName((String) ref.get(Messages.get(Driver.PROGNAME)).getContent());
            ds.setWsid((String) ref.get(Messages.get(Driver.WSID)).getContent());
            final Object tcpNoDelay = ref.get(Messages.get(Driver.TCPNODELAY)).getContent();
            if (tcpNoDelay != null) {
                ds.setTcpNoDelay("true".equals(tcpNoDelay));
            }
            final Object xaEmulation = ref.get(Messages.get(Driver.XAEMULATION)).getContent();
            if (xaEmulation != null) {
                ds.setXaEmulation("true".equals(xaEmulation));
            }
            ds.setLogFile((String) ref.get(Messages.get(Driver.LOGFILE)).getContent());
            ds.setSsl((String) ref.get(Messages.get(Driver.SSL)).getContent());
            final Object batchSize = ref.get(Messages.get(Driver.BATCHSIZE)).getContent();
            if (batchSize != null) {
                ds.setBatchSize(Integer.parseInt((String) batchSize));
            }
            final Object bufferDir = ref.get(Messages.get(Driver.BUFFERDIR)).getContent();
            if (bufferDir != null) {
                ds.setBufferDir((String) bufferDir);
            }
            final Object bufferMaxMemory = ref.get(Messages.get(Driver.BUFFERMAXMEMORY)).getContent();
            if (bufferMaxMemory != null) {
                ds.setBufferMaxMemory(Integer.parseInt((String) bufferMaxMemory));
            }
            final Object bufferMinPackets = ref.get(Messages.get(Driver.BUFFERMINPACKETS)).getContent();
            if (bufferMinPackets != null) {
                ds.setBufferMinPackets(Integer.parseInt((String) bufferMinPackets));
            }
            final Object cacheMetaData = ref.get(Messages.get(Driver.CACHEMETA)).getContent();
            if (cacheMetaData != null) {
                ds.setCacheMetaData("true".equals(cacheMetaData));
            }
            final Object useCursors = ref.get(Messages.get(Driver.USECURSORS)).getContent();
            if (useCursors != null) {
                ds.setUseCursors("true".equals(useCursors));
            }
            final Object useJCIFS = ref.get(Messages.get(Driver.USEJCIFS)).getContent();
            if (useJCIFS != null) {
                ds.setUseJCIFS("true".equals(useJCIFS));
            }
            final Object useLOBs = ref.get(Messages.get(Driver.USELOBS)).getContent();
            if (useLOBs != null) {
                ds.setUseLOBs("true".equals(useLOBs));
            }

            ds.setDescription((String) ref.get("description").getContent());

            return ds;
        }

        return null;
    }
}
