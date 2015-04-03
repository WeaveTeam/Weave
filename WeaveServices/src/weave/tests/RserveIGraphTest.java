/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.tests;

import weave.beans.RResult;
import weave.servlets.RService;

public class RserveIGraphTest 
{
	public static void main(String args[]) throws Exception
	{
		RService rService = new RService();
		String inputNames[] = {};
		Object inputValues[][] = {{}};
		String outputNames[] = {};
		outputNames = new String[3];
		outputNames[0] = "vertexes";
		outputNames[1] = "edges";
		outputNames[2] = "g1";
		String script = "library(igraph)" + "\n"
			+ "\n" + "vertexes <- data.frame(name=c('a','b','c','d'))"
			+ "\n" + "edges <- data.frame(from=c('a','a','a'), to=c('b','c','d'))"
			+ "\n" + "g1 <- graph.data.frame(edges, directed=TRUE, vertices=vertexes)";

//		RResult rresult = new RResult();
//		rresult.setName("test");
		RResult result[];
		try
		{
			result = rService.runScript(null,inputNames, inputValues, outputNames, script, "", false, true,false);
		}
		catch (Exception e)
		{
			throw e;
		}
		System.out.println(result);
		script = "temp <- V(g1)$name";
		outputNames = new String[1];
		outputNames[0] = "temp";
		try
		{
			result = rService.runScript(null,inputNames, inputValues, outputNames, script, "", false, true,false);
		}
		catch (Exception e)
		{
			throw e;
		}
		System.out.println(result);
	}
}
