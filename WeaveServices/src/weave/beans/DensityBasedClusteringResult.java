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

public class DensityBasedClusteringResult {
	private int[] clusterGroup;
	private String[]pointStatus;
	private double[] epsRadius;
	private double[] minimumPoints;

	public DensityBasedClusteringResult(){
		
	}
	public DensityBasedClusteringResult(int[]clusterGroup,
			String[] pointStatus,double[]epsRadius,double[]minimumPoints) {
		this.clusterGroup = clusterGroup;
		this.pointStatus = pointStatus;
		this.epsRadius = epsRadius;
		this.minimumPoints = minimumPoints;
	}
	
	public int[] getClusterGroup(){
		return clusterGroup;
	}
	public String[] getPointStatus(){
		return pointStatus;
	}
	public double[] getEpsRadius(){
		return epsRadius;
	}
	public double[] getminimumPoints(){
		return minimumPoints;
	}
	
	
	public void setClusterGroup(int []clusterGroup){
		this.clusterGroup = clusterGroup; 
	}
	public void setPointStatus(String []pointStatus){
		this.pointStatus = pointStatus;
	}
	public void setEpsRadius(double []epsRadius){
		this.epsRadius = epsRadius;
	}
	public void setMinimumPoints(double[] minimumPoints){
		this.minimumPoints = minimumPoints;
	}
}
