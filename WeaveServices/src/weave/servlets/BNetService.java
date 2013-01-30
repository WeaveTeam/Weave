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

import java.io.IOException;
import java.io.StringReader;
import java.rmi.RemoteException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.WeaveContextParams;


import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.Map;
import java.util.List;
import java.util.LinkedList;
import java.util.Collections;

import com.cra.bnet.engine.*;
import com.cra.shared.graph.*;
import com.cra.bnet.io.XbnFormat;

public class BNetService extends GenericServlet
{
    private Map<String,BayesianNetwork> networks;
	public BNetService()
	{
        networks = new HashMap<String,BayesianNetwork>();
	}
    public List<String> listNetworks()
    {
        return new ArrayList<String>(networks.keySet());
    }
    public List<String> listNodesAsCSV(String netName)
    {
        List<String> result = new LinkedList<String>();
        BayesianNetwork net = networks.get(netName);

        for (Node node : net.nodeSet())
        {
            String nodeName = node.getName();
            String nodeBelief = node.getBelief("true");
            String nodeDescription = node.getDescription();
            result.add(nodeName + "," + nodeBelief);
        }
        return result;
    }
    public List<String> listEdgesAsCSV(String netName)
    {
        List<String> result = new LinkedList<String>();
        BayesianNetwork net = networks.get(netName);
        result.add("edgeId,edgeSource,edgeTarget");
        for (Node node : net.nodeSet())
        {
            for (Node parent : node.getParents())
            {
                String edgeSource = parent.getName();
                String edgeTarget = node.getName();
                String edgeId = edgeSrc+edgeTarget;
                result.add(edgeId + "," + edgeSource + "," + edgeUniq);
            }
        }
        return result;
    }

    public boolean createNetwork(String netName)
    {
        BayesianNetwork net;
        if (networks.get(netName) != null)
        {
            return false;
        }
        else
        {
            net = new BayesianNetwork();
            net.setName(netName);
            networks.put(netName, net);
            return true;
        }
    }
    public void destroyNetwork(String netName)
    {
        networks.remove(netName);
        return;        
    }
    /* Takes an XML string in XBN format describing the Bayesian network, and returns the network id */
    public boolean loadNetwork(String content, String withName) 
    {

        StringReader content_reader = new StringReader(content);
        XbnFormat fmt = new XbnFormat();
        BayesianNetwork net = fmt.read(content_reader);
        if (withName != null && !withName.equals(""))
        {
            net.setName(withName);
        }
        networks.put(net.getName(), net);
        return true;
    }

}
