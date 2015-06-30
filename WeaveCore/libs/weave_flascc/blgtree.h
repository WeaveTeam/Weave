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

/**
 * Binary Line Generalization Tree
 * This class defines a structure to represent a streamed polygon.
 * 
 * Reference: van Oosterom, P. 1990. Reactive data structures
 *  for geographic information systems. PhD thesis, Department
 *  of Computer Science, Leiden University, The Netherlands.
 * 
 * Original code adufilie, ported to C by pkovac
 * 
 * @author adufilie
 * @author pkovac
 * 
 */

#ifndef BLGTREE_H
#define BLGTREE_H

typedef struct Bounds2D bounds_t;
struct Bounds2D {
	double xMin;
	double xMax;
	double yMin;
	double yMax;
};


struct BLGNode;
typedef struct BLGNode blgnode_t;

struct BLGNode {
	int index;
	double importance;
	double x;
	double y;
	blgnode_t* left;
	blgnode_t* right;
};

struct BLGTree;
typedef struct BLGTree blgtree_t;


blgtree_t* blgtree_create(void);
void blgtree_clear(blgtree_t* tree);
void blgtree_destroy(blgtree_t* tree);
char blgtree_is_empty(blgtree_t* tree);
size_t blgtree_size(blgtree_t* tree);
int blgtree_insert(blgtree_t* tree, int index, double importance, double x, double y);
size_t blgtree_get_point_vector(blgtree_t* tree, double min_importance, bounds_t* visible_bounds, blgnode_t* output, size_t output_len_max);
blgtree_t* blgtree_split_at_index(blgtree_t* tree, int split_index);


#endif