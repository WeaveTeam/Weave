/*
** ADOBE SYSTEMS INCORPORATED
** Copyright 2012 Adobe Systems Incorporated
** All Rights Reserved.
**
** NOTICE:  Adobe permits you to use, modify, and distribute this file in accordance with the
** terms of the Adobe license agreement accompanying it.  If you have received this file from a
** source other than Adobe, then your use, modification, or distribution of it requires the prior
** written permission of Adobe.
*/
#ifdef SWIG
%module ShapeLibModule

%{
#include <stdio.h>
#ifdef USE_DBMALLOC
#include <dbmalloc.h>
#endif
#include "source/shapefil.h"
%}

%include "source/shapefil.h"

#else
#include <stdio.h>
#ifdef USE_DBMALLOC
#include <dbmalloc.h>
#endif
#include "source/shapefil.h"
#endif
