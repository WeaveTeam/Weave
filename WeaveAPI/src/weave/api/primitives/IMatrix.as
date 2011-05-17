/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Weave API.
 *
 * The Initial Developer of the Original Code is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2011
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
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