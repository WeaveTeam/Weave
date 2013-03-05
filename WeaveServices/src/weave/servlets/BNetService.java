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

import org.apache.commons.lang3.exception.ExceptionUtils;


import weave.config.WeaveContextParams;

import java.io.FileReader;
import java.io.BufferedReader;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Set;
import java.util.Map;
import java.util.Map.Entry;
import java.util.List;
import java.util.LinkedList;
import java.util.ArrayList;
import java.util.Collections;

import com.cra.bnet.engine.HuginInferenceEngine;
import com.cra.bnet.engine.JunctionTreeInferenceEngine;
import com.cra.bnet.engine.BytecodeInferenceEngine;
import com.cra.bnet.engine.*;
import com.cra.shared.graph.*;
import com.cra.bnet.io.HuginFormat;
import com.cra.bnet.io.XbnFormat;

public class BNetService extends GenericServlet
{
    private Map<String,BayesianNetwork> networks;
	public BNetService() throws RemoteException 
    {
        BayesianNetwork.setDefaultInferenceEngine("com.cra.bnet.engine.HuginInferenceEngine");
        networks = new HashMap<String,BayesianNetwork>();
        /* Load in some networks to start with */
        return;
	}
    public String[] listNetworks() 
    {
        String[] result = (String[])networks.keySet().toArray(new String[0]);
        return result;
    }
    public String[] listNodes(String netName)
    {

        
        BayesianNetwork net = networks.get(netName);
        List<String> result = new ArrayList<String>();
        for (DiscreteNode node : net.discreteNodeSet())
        {
            String nodeName = node.getName();
            result.add(nodeName);
        }
        return (String[])result.toArray(new String[0]);
    }
    public String[] getNodeParents(String netName, String nodeName)
    {
        List<String> result = new ArrayList<String>();

        BayesianNetwork net = networks.get(netName);
        DiscreteNode node = net.getDiscreteNode(nodeName);
        List<DiscreteNode> parents = node.getParents();
        for (DiscreteNode parent : parents)
        {
            result.add(parent.getName());
        }
        
        return (String[])result.toArray(new String[0]);
    }
    public String[] listStates(String netName)
    {
        /* Compute the union of all the states of all the nodes in network netName */
        Set<String> states = new HashSet<String>();
        BayesianNetwork net = networks.get(netName);
        for (DiscreteNode node : net.discreteNodeSet())
        {
            states.addAll(node.getStates());
        }
        return (String[])states.toArray(new String[0]);
    }
    public Map<String,Double> getNodeBeliefs(String netName, String nodeName)
    {
        Map<String,Double> beliefs = new HashMap<String,Double>();
        BayesianNetwork net = networks.get(netName);
        DiscreteNode node = net.getDiscreteNode(nodeName);
        String[] states = (String[])node.getStates().toArray(new String[0]);
        double[] raw_beliefs = node.getBeliefs();
        assert states.length == raw_beliefs.length;
        for (int i = 0; i < states.length; i++)
        {
            beliefs.put(states[i], new Double(raw_beliefs[i]));
        }
        return beliefs;
    }
    public Map<String,Double> getNodeEvidence(String netName, String nodeName)
    {
        Map<String,Double> evidence = new HashMap<String,Double>();
        BayesianNetwork net = networks.get(netName);
        DiscreteNode node = net.getDiscreteNode(nodeName);
        List<String> states = node.getStates();
        for (String state : states)
        {
            evidence.put(state, node.getEvidence(state));
        }
        return evidence;
    }
    public void setNodeEvidence(String netName, String nodeName, Map<String,Double> evidence)
    {
        BayesianNetwork net = networks.get(netName);
        DiscreteNode node = net.getDiscreteNode(nodeName);
        for (Entry<String,Double> datum : evidence.entrySet())
        {
            node.setEvidence(datum.getKey(), datum.getValue());
        }
        return;
    }
    public void loadNetwork(String path, String withName) throws RemoteException
    {
        if (withName == null || withName.equals(""))
        {
            throw new RemoteException("withName must not be empty or null.", null);
        }
        if (networks.get(withName) != null)
        {
            throw new RemoteException("Network named \'" + withName + "\' already exists.", null);
        }
        File f = new File(path);
        if (!f.exists())
        {
            throw new RemoteException("Network file named \'" + path + "\' not found.", null);
        }
        BayesianNetwork net = null;
        try {
            net = XbnFormat.read(new File(path));
            if (net == null)
                throw new Exception("Network failed to load.");
        }
        catch (Exception e)
        {
            throw new RemoteException("Failed to load network.",e);
        }
        networks.put(withName, net);
    }
}
