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

import java.lang.StringBuilder;
import java.io.IOException;
import java.io.StringReader;
import java.io.File;
import java.rmi.RemoteException;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;

import weave.config.WeaveContextParams;

import java.io.FileReader;
import java.io.BufferedReader;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.Map;
import java.util.List;
import java.util.LinkedList;
import java.util.Collections;

import com.cra.bnet.engine.*;
import com.cra.shared.graph.*;
import com.cra.bnet.io.HuginFormat;
import com.cra.bnet.io.XbnFormat;

public class BNetService extends GenericServlet
{
    private Map<String,BayesianNetwork> networks;
	public BNetService() throws RemoteException
	{
        networks = new HashMap<String,BayesianNetwork>();
        return;
	}
    public List<String> listNetworks()
    {
        return new LinkedList<String>(networks.keySet());
    }
    public String listNodes(String netName)
    {

        StringBuilder result = new StringBuilder();
        BayesianNetwork net = networks.get(netName);
        result.append("nodeName,nodeBelief");
        for (DiscreteNode node : net.discreteNodeSet())
        {
            String nodeName = node.getName();
            String nodeBelief = "" + node.getBelief("true");
            String nodeDescription = node.getDescription();
            result.append(nodeName + "," + nodeBelief + "\n");
        }
        return result.toString();
    }
    public String listEdges(String netName)
    {
        StringBuilder result = new StringBuilder();
        BayesianNetwork net = networks.get(netName);
        result.append("edgeId,edgeSource,edgeTarget\n");
        for (Node node : net.discreteNodeSet())
        {
            List<Node> parents = new LinkedList<Node>(node.getParents());
            for (Node parent : parents)
            {
                String edgeSource = parent.getName();
                String edgeTarget = node.getName();
                String edgeId = edgeSource+edgeTarget;
                result.append(edgeId + "," + edgeSource + "," + edgeId + "\n");
            }
        }
        return result.toString();
    }
    public void postEvidence(String netName, String nodeName, double value)
    {
        BayesianNetwork net = networks.get(netName);
        DiscreteNode node = net.getDiscreteNode(nodeName);
        node.setEvidence("true", value);
        node.setEvidence("false", 1.0-value);
        return;
    }
    /* Takes an XML string in XBN format describing the Bayesian network, and returns the network id */
    public boolean loadNetwork(String path, String withName) throws RemoteException
    {
        File f = new File(path);
        if (f.exists())
        {
            System.out.println("Located network file.");
        }

        BayesianNetwork net = XbnFormat.read(new File(path));
        if (withName != null && !withName.equals(""))
        {
            net.setName(withName);
        }
        networks.put(net.getName(), net);
        return true;
    }
    

}
