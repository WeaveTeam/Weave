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
			result = rService.runScript(inputNames, inputValues, outputNames, script, "", false, true);
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
			result = rService.runScript(inputNames, inputValues, outputNames, script, "", false, true);
		}
		catch (Exception e)
		{
			throw e;
		}
		System.out.println(result);
	}
}
