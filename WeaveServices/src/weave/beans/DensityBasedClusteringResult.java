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
