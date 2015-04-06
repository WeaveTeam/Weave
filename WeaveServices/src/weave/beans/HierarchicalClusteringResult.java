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

public class HierarchicalClusteringResult {
	private double [][]clusterSequence;
	private String []clusterMethod;
	//private String []clusterLabels;
	private String []clusterDistanceMeasure;

	public HierarchicalClusteringResult(){
		
		}
	public HierarchicalClusteringResult(double[][] clusterSequence, String[]clusterMethod, String[] clusterLabels,
									String[] clusterDistanceMeasure) {
		this.clusterSequence = clusterSequence;
		this.clusterMethod = clusterMethod;
		//this.clusterLabels = clusterLabels;
		this.clusterDistanceMeasure = clusterDistanceMeasure;

	}
		public double[][]getClusterSequence(){
			return clusterSequence;
		}
		public String[] getClusterMethod(){
			return clusterMethod;
		}
		/*public String[] getClusterLabels(){
			return clusterLabels;
		}*/
		public String [] getClusterDistanceMeasure(){
			return clusterDistanceMeasure;
		}
		
		
		
		public void setClusterSequence(double[][]clusterSequence){
			this.clusterSequence = clusterSequence;
		}
		public void setClusterMethod(String[] clusterMethod){
			this.clusterMethod = clusterMethod;
		}
		/*public void setClusterLabels(String [] clusterLabels){
			this.clusterLabels = clusterLabels;
		}*/
		public void setClusterDistanceMeasure(String[]clusterDistanceMeasure){
			this.clusterDistanceMeasure = clusterDistanceMeasure;
		}
}


