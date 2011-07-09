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

package weave.primitives
{
	import weave.api.primitives.IMatrix;
	import weave.core.ErrorManager;

	/**
	 * This class defines the general operations for a matrix which will not change
	 * if the matrix is square or rectangular.
	 * 
	 * @author kmonico
	 */
	public class WeaveMatrix implements IMatrix
	{
		public function WeaveMatrix(rows:int, columns:int)
		{
			setDimensions(rows, columns);
		}
		
		/**
		 * The matrix is internally represented as a one dimensional vector of
		 * numbers.
		 */
		protected var _matrix:Vector.<Number> = null;
		protected var _rows:int = 0; // the number of rows, also interpreted as the height
		protected var _columns:int = 0; // the number of columns, also interpreted as the width
		
		public function setEntry(value:Number, row:int, column:int):void
		{
			this._matrix[row * this._columns + column] = value;
		}
		
		public function getEntry(row:int, column:int):Number
		{
			return this._matrix[row * this._columns + column];
		}
		
		public function setDimensions(rows:int, columns:int):void
		{
			this._rows = rows;
			this._columns = columns;
			
			this._matrix = new Vector.<Number>();
			for (var i:int = 0; i < rows * columns; ++i)
				this._matrix[i] = 0;
		}
		
		public function getHeight():int
		{
			return this._rows;
		}
		
		public function getWidth():int
		{
			return this._columns;
		}
		
		public function add(rightHandSide:IMatrix):IMatrix
		{
			if (this._rows != rightHandSide.getHeight() 
				|| this._columns != rightHandSide.getWidth())
			{
				ErrorManager.reportError(new Error("Invalid matrix addition."));
				return null;
			}

			for (var i:int = 0; i < this._rows; ++i)
			{
				for (var j:int = 0; j < this._columns; ++j)
				{
					this.setEntry(
						this.getEntry(i, j) + rightHandSide.getEntry(i, j),
						i, j
					);
				}
			}

			return this;
		}
		
		public function subtract(rightHandSide:IMatrix):IMatrix
		{
			if (this._rows != rightHandSide.getHeight() 
				|| this._columns != rightHandSide.getWidth())
			{
				ErrorManager.reportError(new Error("Invalid matrix subtraction."));
				return null;
			}

			for (var i:int = 0; i < this._rows; ++i)
			{
				for (var j:int = 0; j < this._columns; ++j)
				{
					this.setEntry(
						this.getEntry(i, j) - rightHandSide.getEntry(i, j),
						i, j
					);
				}
			}

			return this;
		}
		
		public function multiply(rightHandSide:IMatrix):IMatrix
		{
			// this matrix's number of columns must equal the other matrix's number of rows
			if (_columns != rightHandSide.getHeight())
			{
				ErrorManager.reportError(new Error("Invalid matrix multiplication."));
				return null;
			}
			
			// multiplication isn't in-place--need a copy
			var copyMatrix:IMatrix = this.cloneMatrix();
			this.setDimensions(this._rows, rightHandSide.getWidth());
			
			// perform the operation setting each result's entry
			for (var i:int = 0; i < _rows; ++i)
			{
				for (var j:int = 0; j < _columns; ++j)
				{
					for (var k:int = 0; k < rightHandSide.getHeight(); ++k)
					{
						this.setEntry(
							this.getEntry(i, j) + copyMatrix.getEntry(i, k) * rightHandSide.getEntry(k, j),
							i, j
						);
					}
				}
			}
			
			return this;
		}
		
		public function invert():IMatrix
		{
			var k:int;
			var i:int;
			var j:int;
			for (k = 0; k < this._columns - 1; ++k)
			{
				// if the diagonal has a 0, this matrix is singular
				var pivot:Number = this.getEntry(k, k);
				if (pivot == 0) 
				{
					ErrorManager.reportError(new Error("Attempt to invert singular matrix."));
					return null;
				}
				
				for (i = k + 1; i < this._columns; ++i)
					this.setEntry( 
						this.getEntry(i, k) / pivot,
						i, k
					);
				
				for (j = k + 1; j < this._columns; ++j)
				{
					for (i = k + 1; i < this._columns; ++i)
					{
						this.setEntry(
							this.getEntry(i, j) - this.getEntry(i, k) * this.getEntry(k, j),
							i, j
						);
					}
				}
			}
			
			return this;
		}
		
		public function cloneMatrix(result:IMatrix = null):IMatrix
		{
			if (result == null)
				result = new WeaveMatrix(this._rows, this._columns);
			
			if (result.getHeight() != this._rows
				|| result.getWidth() != this._columns)
			{
				ErrorManager.reportError(new Error("Invalid result matrix provided."));
				return result;
			}
			
			// clone everything
			for (var i:int = 0; i < this._rows; ++i)
				for (var j:int = 0; j < this._columns; ++j)
					result.setEntry(
						this.getEntry(i, j),
						i, j
					);
			
			return result;
		}
		
		public function copyFrom(other:IMatrix):void
		{
			if (other.getHeight() != this._rows 
				|| other.getWidth() != this._columns)
			{
				ErrorManager.reportError(new Error("Invalid matrix to copy."));
				return;
			}
			
			for (var i:int = 0; i < this._rows; ++i)
				for (var j:int = 0; j < this._columns; ++j)
					this.setEntry(
						other.getEntry(i, j),
						i, j
					);
		}
	}
}