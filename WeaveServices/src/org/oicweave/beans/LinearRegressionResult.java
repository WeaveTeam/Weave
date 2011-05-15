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

public class LinearRegressionResult {
	private double slope, intercept, rSquared;
	private String summary;
	private String[] keys;
	private double[] residual;
	
	public LinearRegressionResult() {
	}

	public LinearRegressionResult(double slope, double intercept,
			double rSquared, String summary, String[] keys, double[] residual) {
		this.slope = slope;
		this.intercept = intercept;
		this.rSquared = rSquared;
		this.summary = summary;
		this.keys = keys;
		this.residual = residual;
	}
	
	public void setSummary(String summary) {
		this.summary = summary;
	}
	
	public void setResidual(double[] residual) {
		this.residual = residual;
	}
	
	public String[] getKeys() {
		return keys;
	}
	
	public void setKeys(String[] keys) {
		this.keys = keys;
	}
	
	public double getSlope() {
		return slope;
	}

	public void setSlope(double slope) {
		this.slope = slope;
	}

	public double getIntercept() {
		return intercept;
	}

	public void setIntercept(double intercept) {
		this.intercept = intercept;
	}

	public double getRSquared() {
		return rSquared;
	}

	public void setRSquared(double squared) {
		rSquared = squared;
	}
	
	public String getSummary() {
		return summary;
	}
    
	public double[] getResidual() {
		return residual;
	}

}
