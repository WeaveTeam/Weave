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

public class HierarchalClusteringResult {
	private double [][]clusterSequence;
	private String []clusterMethod;
	private String []clusterLabels;
	private String []clusterDistanceMeasure;

	public HierarchalClusteringResult(){
		
		}
	public HierarchalClusteringResult(double[][] clusterSequence, String[]clusterMethod, String[] clusterLabels,
									String[] clusterDistanceMeasure) {
		this.clusterSequence = clusterSequence;
		this.clusterMethod = clusterMethod;
		this.clusterLabels = clusterLabels;
		this.clusterDistanceMeasure = clusterDistanceMeasure;

	}
		public double[][]getClusterSequence(){
			return clusterSequence;
		}
		public String[] getClusterMethod(){
			return clusterMethod;
		}
		public String[] getClusterLabels(){
			return clusterLabels;
		}
		public String [] getClusterDistanceMeasure(){
			return clusterDistanceMeasure;
		}
		
		
		
		public void setClusterSequence(double[][]clusterSequence){
			this.clusterSequence = clusterSequence;
		}
		public void setClusterMethod(String[] clusterMethod){
			this.clusterMethod = clusterMethod;
		}
		public void setClusterLabels(String [] clusterLabels){
			this.clusterLabels = clusterLabels;
		}
		public void setClusterDistanceMeasure(String[]clusterDistanceMeasure){
			this.clusterDistanceMeasure = clusterDistanceMeasure;
		}
}


