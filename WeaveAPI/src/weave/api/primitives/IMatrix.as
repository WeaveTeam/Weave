/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of the Weave API.
 *
 * The Initial Developer of the Weave API is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2012
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.api.primitives
{
	/**
	 * IMatrix provides an interface to a two dimensional array of numbers.
	 * Operations allowed on an IMatrix are addition, subtraction, multiplication,
	 * and inversion. All of these operations are in-place on this matrix and return
	 * this matrix to allow nesting.
	 * Uninitialized entries in the array default to 0 to imitate sparse 
	 * matrices.
	 * 
	 * @author kmonico
	 */
	public interface IMatrix
	{
		/**
		 * Sets a value at the entry in the matrix specified by row and column.
		 * 
		 * @param value The value to set.
		 * @param row The row of the matrix.
		 * @param column The column of the matrix.
		 */
		function setEntry(value:Number, row:int, column:int):void;	
		
		/**
		 * Gets a value at the entry in the matrix specified by row and column.
		 * 
		 * @param row The row of the matrix.
		 * @param column The column of the matrix.
		 * @return The value at the matrix's row, column cell.
		 */
		function getEntry(row:int, column:int):Number;
		
		/**
		 * Sets the dimensions of the matrix.
		 * 
		 * @param rows The new number of rows.
		 * @param columns The new number of columns.
		 */
		function setDimensions(rows:int, columns:int):void;
		
		/**
		 * Gets the height of the matrix, which is defined as the number of rows.
		 *
		 * @return The number of rows.
		 */
		function getHeight():int;
		
		/**
		 * Gets the width of the matrix, which is defined as the number of columns.
		 *
		 * @return The number of columns.
		 */
		function getWidth():int;
			
		/**
		 * This function will add this matrix to the other matrix and store the 
		 * result in result.
		 * this + rightHandSide
		 * 
		 * @param rightHandSide The other matrix.
		 * @return This matrix.
		 */
		function add(rightHandSide:IMatrix):IMatrix;
		
		/**
		 * This function will subtract the other matrix from this one and store the 
		 * result in result.
		 * this - rightHandSide
		 * 
		 * @param rightHandSide The other matrix.
		 * @return Tis matrix after the subtraction.
		 */
		function subtract(rightHandSide:IMatrix):IMatrix;
		
		/**
		 * This function will multiply this matrix to the other matrix and store the 
		 * result in result.
		 * this * rightHandSide
		 * 
		 * @param rightHandSide The other matrix.
		 * @return This matrix after the multiplication.
		 */		
		function multiply(rightHandSide:IMatrix):IMatrix;
		
		/**
		 * This function will invert this matrix.
		 * 
		 * @return This matrix after the inversion.
		 */
		function invert():IMatrix;
		
		/**
		 * This function will clone this matrix and return the result.
		 * 
		 * @param result The matrix to store the result.
		 * @return The cloned matrix, result.
		 */
		function cloneMatrix(result:IMatrix = null):IMatrix;
		
		/**
		 * This function will copy the entries of the other matrix into this matrix.
		 * 
		 * @param other The other matrix.
		 */
		function copyFrom(other:IMatrix):void;
	}
}