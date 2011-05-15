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

package org.oicweave.utils;

import java.util.LinkedList;
import java.util.Stack;
import java.util.Vector;

/**
 * This class defines a K-Dimensional Tree.
 * 
 * @author adufilie
 */
public class KDTree<T>
{
	/**
	 * Constructs an empty KDTree with the given dimensionality.
	 * 
	 * TODO: add parameter for a list of key,object pairs and create a balanced tree from those.
	 */
	public KDTree(int dimensionality)
	{
		if (dimensionality <= 0)
			throw new RuntimeException("KDTree dimensionality must be > 0");
		this.dimensionality = dimensionality;
	}
	
	/**
	 * The dimensionality of the KDTree.
	 */
	private int dimensionality;

	/**
	 * This list of nodes should not be modified outside the KDTree class definition.
	 * This list is exposed so the nodes can be iterated over quickly.
	 */
	public LinkedList<KDNode<T>> allNodes = new LinkedList<KDNode<T>>();
	
	/**
	 * This is the root of the tree.
	 */
	private KDNode<T> rootNode = null;

	/**
	 * Constructs a k-dimensional key out of k parameters.
	 */
	public static double[] makeKey(double ... keyValues)
	{
		return keyValues;
	}
	
	/**
	 * Compares two k-dimensional keys.
	 * @param key1 A k-dimensional key
	 * @param key2 Another k-dimensional key
	 * @return true if the keys are equal
	 */
	public static boolean keysAreEqual(double[] key1, double[] key2)
	{
		if (key1.length != key2.length)
			return false;
		double value1, value2;
		for (int i = key1.length - 1; i >= 0; i--)
		{
			value1 = key1[i];
			value2 = key2[i];
			if (Double.isNaN(value1) && Double.isNaN(value2))
				continue;
			if (value1 != value2)
				return false;
		}
		return true;
	}
	
	/**
	 * This function inserts a new key,object pair into the KDTree.
	 * Warning: This function could cause the tree to become unbalanced and degrade performance.
	 * @param key The k-dimensional key that corresponds to the object.
	 * @param object The object to insert in the tree.
	 * @return A KDNode object that can be used as a parameter to the remove() function.
	 */
	public KDNode<T> insert(double[] key, T obj)
	{
		if (key.length != dimensionality)
			throw new RuntimeException("KDTree.insert key parameter must have same dimensionality as tree");

		// base case: if object is null, don't insert it in the tree.
		if (obj == null)
			return null;
		// base case: if the tree is empty, store this key,object pair at the root node
		if (rootNode == null)
		{
			rootNode = new KDNode<T>(key, obj, 0);
			allNodes.add(rootNode);
			return rootNode;
		}
		KDNode<T> node = rootNode;
		while (true)
		{
			if (key[node.splitDimension] < node.location)
			{
				// left side
				if (node.left == null)
				{
					// no node to the left, insert there
					node.left = new KDNode<T>(key, obj, (node.splitDimension + 1) % dimensionality);
					allNodes.add(node.left);
					return node.left;
				}
				// go down the tree
				node = node.left;
			}
			else // key >= location
			{
				// right side
				if (node.right == null)
				{
					// no node to the right, insert there
					node.right = new KDNode<T>(key, obj, (node.splitDimension + 1) % dimensionality);
					allNodes.add(node.right);
					return node.right;
				}
				// go down the tree
				node = node.right;
			}
		}
	}

	/**
	 * Finds a node with a matching key.
 	 * @param key The key to find
	 * @return A node with a matching key, or null if no node was found.
	 */
	public KDNode<T> find(double[] keyToFind)
	{
		if (keyToFind.length != dimensionality)
			throw new RuntimeException("KDTree.find key parameter must have same dimensionality as tree");

		// only continue if root node is not null and rootNode location is defined
		if (rootNode != null && !Double.isNaN(rootNode.location))
		{
			// declare temp variables
			KDNode<T> node;
			int dimension;
			double location;
			// traverse the tree
			// begin by putting the root node on the stack
			Stack<KDNode<T>> nodeStack = new Stack<KDNode<T>>();
			nodeStack.add(rootNode);
			// loop until the stack is empty
			while (!nodeStack.isEmpty())
			{
				// pop a node off the stack
				node = nodeStack.pop();
				
				if (keysAreEqual(node.key, keyToFind))
					return node;
				
				dimension = node.splitDimension;
				location = node.location;

				// traverse left as long as there may be results on the left side of the splitting plane
				if (node.left != null && keyToFind[dimension] <= location)
				{
					// push left child node on the stack
					nodeStack.push(node.left);
				}
				
				// traverse right as long as there may be results on the right side of the splitting plane
				if (node.right != null && location <= keyToFind[dimension])
				{
					// push right child node on the stack
					nodeStack.push(node.right);
				}
			}
		}
		return null;
	}

	/**
	 * Remove all nodes from the tree.
	 */
	public void clear()
	{
		rootNode = null;
		allNodes.clear();
	}

	/**
	 * This function returns an array of pointers to objects with keys that fall
	 * between minKey and maxKey, inclusive.
	 */
	public Vector<T> queryRange(double[] minKey, double[] maxKey)
	{
		Vector<T> queryResult = new Vector<T>();
		if (minKey.length != dimensionality || maxKey.length != dimensionality)
			throw new RuntimeException("KDTree.rangeQuery parameters must have same dimensionality as tree");
		
		// only continue if root node is not null and rootNode location is defined
		if (rootNode != null && !Double.isNaN(rootNode.location))
		{
			// declare temp variables
			boolean inRange;
			KDNode<T> node;
			double[] key;
			double keyVal;
			int dimension;
			double location;
			// traverse the tree
			// begin by putting the root node on the stack
			Stack<KDNode<T>> nodeStack = new Stack<KDNode<T>>();
			nodeStack.add(rootNode);
			// loop until the stack is empty
			while (!nodeStack.isEmpty())
			{
				// pop a node off the stack
				node = nodeStack.pop();
				
				key = node.key;
				dimension = node.splitDimension;
				location = node.location;

				if (node.object != null) // only append non-null objects to queryResult
				{
					// see if this node falls within query range
					inRange = true;
					for (int i = 0; i < dimensionality; i++)
					{
						keyVal = key[i];
						if (keyVal < minKey[i] || keyVal > maxKey[i])
						{
							inRange = false; // no hit if key out of range
							break;
						}
					}
					// if this node is in range, append associated object to query results
					if (inRange)
						queryResult.add(node.object);
				}
				
				// traverse left as long as there may be results on the left side of the splitting plane
				if (node.left != null && minKey[dimension] <= location)
				{
					// push left child node on the stack
					nodeStack.push(node.left);
				}
				
				// traverse right as long as there may be results on the right side of the splitting plane
				if (node.right != null && location <= maxKey[dimension])
				{
					// push right child node on the stack
					nodeStack.push(node.right);
				}
			}
		}
		return queryResult;
	}
}
