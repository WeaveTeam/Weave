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

package weave.beans;

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
