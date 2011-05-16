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

package weave.geometrystream;

import java.util.Stack;

/**
 * @author adufilie
 */
public class VertexIdentifier
{
	/**
	 * The constructor is private because it should not be used externally.
	 * Instead, use the static getUsedInstance() function.
	 */
	private VertexIdentifier()
	{
	}
	
	int shapeID;
	int vertexID;
	
	private static Stack<VertexIdentifier> unusedInstances = new Stack<VertexIdentifier>();
	/**
	 * This puts an unused instance of VertexIdentifier into the object pool so it can be reused later.
	 * @param instance An instance of VertexIdentifier that is no longer needed.
	 */
	public static void saveUnusedInstance(VertexIdentifier instance)
	{
		unusedInstances.push(instance);
	}
	/**
	 * @param shapeID The integer that identifies the shape this vertex belongs to.
	 * @param vertexID The integer that identifies the vertex within the shape.
	 * @return Either a VertexIdentifier object from the pool or a new one.
	 */
	public static VertexIdentifier getUnusedInstance(int shapeID, int vertexID)
	{
		VertexIdentifier result;
		if (unusedInstances.size() == 0)
			result = new VertexIdentifier();
		else
			result = unusedInstances.pop();
		result.shapeID = shapeID;
		result.vertexID = vertexID;
		return result;
	}
}
