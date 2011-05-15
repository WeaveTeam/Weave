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
package org.oicweave.beans;

public class KMeansClusteringResult {
	private double[][] clusterMeans;
	private double[] clusterSize;
	private double[]withinSumOfSquares;
	private double[]clusterGroup;
	private String RImageFilePath;

public KMeansClusteringResult(){
	}

public KMeansClusteringResult(double[][] clusterMeans,
		double[] clusterSize,double[]withinSumOfSquares,double[]clusterGroup, String RImageFilePath) {
	this.clusterMeans = clusterMeans;
	this.clusterSize = clusterSize;
	this.withinSumOfSquares = withinSumOfSquares;	
	this.clusterGroup = clusterGroup;
	this.RImageFilePath = RImageFilePath;
}

	public double[][] getClusterMeans(){
		return clusterMeans;
	}
	
	public double[] getClusterSize(){
		return clusterSize;
	}

	public double[] getWithinSumOfSquares(){
		return withinSumOfSquares;
	}
	
	public double[] getClusterGroup(){
		return clusterGroup;
	}
	
	public String getRImageFilePath(){
		return RImageFilePath;
	}
	
	public void setClusterMeans(double[][]clusterMeans){
		this.clusterMeans = clusterMeans;
	}
	
	public void setClusterSize(double[]clusterSize){
		this.clusterSize = clusterSize;
	}
	
	public void setWithinSumOfSquares( double[] withinSumOfSquares){
		this.withinSumOfSquares = withinSumOfSquares;
	}
	
	public void setClusterGroup(double[] clusterGroup){
		this.clusterGroup = clusterGroup;
	}
	public void setRImageFilePath(String RImageFilePath){
		this.RImageFilePath = RImageFilePath;
	}
}
