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

public class BNetService extends GenericServlet
{
    private Map<Integer,BayesianNetwork> networks;
    int nextNetId = 0;
	public BNetService()
	{
        networks = new HashMap<Integer,BayesianNetwork>();
	}
    public int createNetwork(String name)
    {
        int id = nextNetId++;
        BayesianNetwork net = new BayesianNetwork();
        net.setName(name);
        networks.put(id, net);
        return id;
    }
    public void destroyNetwork(int netId)
    {
        networks.remove(netId);
        return;        
    }
    public boolean addNode(int netId, String nodeName)
    {
        BayesianNetwork net = networks.get(netId);
        return net.addDiscreteNode(nodeName) != null;
    }
    public boolean removeNode(int netId, String nodeName)
    {
        BayesianNetwork net = networks.get(netId);
        Node node = net.getNode(nodeName);
        return net.removeNode(node);
    }
    public void addEdge(int netId, String srcNodeName, String destNodeName)
    {
        BayesianNetwork net = networks.get(netId);
        Node srcNode = net.getNode(srcNodeName);
        Node destNode = net.getNode(destNodeName);
        net.addEdge(srcNode, destNode);
    }
    public void removeEdge(int netId, String srcNodeName, String destNodeName)
    {
        BayesianNetwork net = networks.get(netId);
        Node srcNode = net.getNode(srcNodeName);
        Node destNode = net.getNode(destNodeName);
        net.removeEdge(srcNode, destNode);
    }
    public List<String> listNodes(int netId)
    {
        List<String> result = new LinkedList<String>();
        return result;
    }
    public List<String> listEdges(int netId, String srcNodeName)
    {
        List<String> result = new LinkedList<String>();
        return result;
    }
    public void setEvidence(int netId, String nodeName, boolean b, double value)
    {
        return;
    }
}
