// stdafx.h : include file for standard system include files,
//  or project specific include files that are used frequently, but
//      are changed infrequently
//

#if !defined(AFX_STDAFX_H__08B16F02_8C54_45BF_8112_22D94C1759E0__INCLUDED_)
#define AFX_STDAFX_H__08B16F02_8C54_45BF_8112_22D94C1759E0__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000


// Insert your headers here
#define WIN32_LEAN_AND_MEAN		// Exclude rarely-used stuff from Windows headers

// TODO: reference additional headers your program requires here
#define SECURITY_WIN32

#ifdef _UNICODE
#define INIT_SEC_INTERFACE_NAME       "InitSecurityInterfaceW"
#else
#define INIT_SEC_INTERFACE_NAME       "InitSecurityInterfaceA"
#endif

#include <stdio.h>
#include <string.h>
#include <tchar.h>
#include <windows.h>
#include <sspi.h>
#include <schnlsp.h>
#include <jni.h>
#include <vector>
#include <rpc.h>
#include <rpcdce.h>
#include "ntlm_SSPIJNIClient.h"


//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STDAFX_H__08B16F02_8C54_45BF_8112_22D94C1759E0__INCLUDED_)
