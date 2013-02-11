// jTDS JDBC Driver for Microsoft SQL Server and Sybase
// Copyright (C) 2004 The jTDS Project
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//

#include "StdAfx.h"

//
// JNI DLL to implement Windows authentication.
// Based on code submitted by Magendran Sathaiah.
//

//
// Class to hold per thread context information
//
class Context {
    public:
        CredHandle  m_Credentials;
        CtxtHandle  m_Context;
};

//
// Global variables
//
PSecurityFunctionTable  pSecurityInterface = NULL;      // security interface table


HINSTANCE               hProvider          = NULL;      // provider dll's instance


ULONG                   cbMaxToken;                     // Length of NTLM security token

SEC_CHAR*               Name;                           // Name of security provider

DWORD                   tlsIndex;                       // Thread Local Storage Index

//
// Throw this java exception for all local errors
//
void IllegalStateException(JNIEnv *env, const char* szMsg) 
{
    jclass newEx;
    newEx = env->FindClass("java/lang/IllegalStateException");
    if (newEx != NULL) {
        env->ThrowNew(newEx, szMsg);
    }
}

//
// Initialize the DLL and security interface
//
JNIEXPORT void JNICALL Java_net_sourceforge_jtds_util_SSPIJNIClient_initialize
                                    (JNIEnv * env, jobject obj) 
{
    // TODO: Remove this stub and the native call in SSPIJNIClient.java
}

//
// The real initialize routine called by System.loadlibrary
//
JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *jvm, void *reserved) {
    JNIEnv *env;
    if ((jvm->GetEnv((void **)&env, JNI_VERSION_1_2))) {
        return JNI_ERR; // JNI Version not supported! 
    }
    // 
    // Allocate thread local storage
    //
    tlsIndex    = TlsAlloc();
    //
    // Load security provider library
    //
	hProvider   = LoadLibrary ( _T("secur32.dll") );
    if ( hProvider == NULL ) {
        // secur32.dll not normally available on windows NT < 5.0
        hProvider = LoadLibrary ( _T("security.dll") );
        if (hProvider == NULL) {
            // Neither found so give up!
    		IllegalStateException(env, "Unable to load secur32.dll or security.dll");
            return JNI_VERSION_1_2;
        }
    }
   
	INIT_SECURITY_INTERFACE InitSecurityInterface;
    //
    // Get the address of the InitSecurityInterface function.
    //
	InitSecurityInterface = reinterpret_cast<INIT_SECURITY_INTERFACE> (
										      GetProcAddress (
													hProvider,
													INIT_SEC_INTERFACE_NAME
												)
										 );
    if ( InitSecurityInterface == NULL ) {
  		IllegalStateException(env, "Unable to locate SecurityInterface in security.dll");
        return JNI_VERSION_1_2;
    }
    
    //
    // Initialize the security interface
    //
   	pSecurityInterface = InitSecurityInterface ( );
    if ( pSecurityInterface == NULL ) {
  		IllegalStateException(env, "Unable to initialisze SecurityInterface");
        return JNI_VERSION_1_2;
    }

    SecPkgInfo* pPackage = NULL;
    //
    // Locate information about the NTLM security provider
    //
    SECURITY_STATUS status = 
        pSecurityInterface->QuerySecurityPackageInfo (_T("NTLM"), &pPackage);
    if ( status != SEC_E_OK ) {
  		IllegalStateException(env, "NTLM Security package not supported");
        return JNI_VERSION_1_2;
    }
    //
    // Save the relevant information for later
    //
    cbMaxToken = pPackage->cbMaxToken;
    Name = _tcsdup(pPackage->Name);
    //
    // Finished with information buffer now
    //
    if ( pSecurityInterface->FreeContextBuffer != NULL ) {
         pSecurityInterface->FreeContextBuffer ( (void*) pPackage );
    }

    return JNI_VERSION_1_2;
}

//
// Java 2 method called when DLL is unloaded.
//
JNIEXPORT void JNICALL JNI_OnUnload(JavaVM *jvm, void *reserved)
{

	FreeLibrary ( hProvider );
    hProvider = NULL;
    pSecurityInterface = NULL;
    TlsFree(tlsIndex);
}

//
// Useful for unloading the DLL in testing
//
JNIEXPORT void JNICALL Java_net_sourceforge_jtds_util_SSPIJNIClient_unInitialize
(JNIEnv * env, jobject obj) {
    // TODO: Remove this method and the native call in SSPIJNIClient.java
	FreeLibrary ( hProvider );
    hProvider = NULL;
    pSecurityInterface = NULL;
    TlsFree(tlsIndex);
}

//
// Called to obtain the outbound security credentials to send with the 
// SQL Server login packet.
//
JNIEXPORT jbyteArray JNICALL Java_net_sourceforge_jtds_util_SSPIJNIClient_prepareSSORequest
                                    (JNIEnv *env, jobject obj) 
{
    //
    // Create the object to hold the security context
    // and save in thread local storage.
    //
    Context* context = new Context();
    if (context == NULL ) {
        IllegalStateException(env, "Out of memory creating security context");
        return NULL;
    }
    TlsSetValue(tlsIndex, context);

    TimeStamp           Expiration;
    SECURITY_STATUS     status;
    //
    // Obtain the credentials of the local logged in user
    //
    status = pSecurityInterface->AcquireCredentialsHandle ( 
                            NULL,
                            Name,
                            SECPKG_CRED_OUTBOUND,
                            NULL, NULL,
                            NULL, NULL,
                            &context->m_Credentials,
                            &Expiration
                        );
    if ( status != SEC_E_OK ) {
        IllegalStateException(env, "Unable to acquire credentials");
    }

    SecBufferDesc   obd;
    SecBuffer       ob;
    BYTE*           pToken;        

    // prepare outbound buffer
    ob.BufferType = SECBUFFER_TOKEN;
    ob.cbBuffer   = cbMaxToken;
    pToken     = new BYTE[ob.cbBuffer];
    if ( pToken == NULL ) {
        IllegalStateException(env, "Out of memory creating security token");
        return NULL;
    }
    ob.pvBuffer   = pToken;
    // prepare buffer description
    obd.cBuffers  = 1;
    obd.ulVersion = SECBUFFER_VERSION;
    obd.pBuffers  = &ob;

    DWORD      CtxtAttr;

    // 
    // Now create outbound security context
    //
    status = pSecurityInterface->InitializeSecurityContext ( 
                            &context->m_Credentials,
                            NULL,
                            NULL,
                            ISC_REQ_REPLAY_DETECT | ISC_REQ_SEQUENCE_DETECT |
                            ISC_REQ_CONFIDENTIALITY | ISC_REQ_DELEGATE, 
                            0,
                            SECURITY_NATIVE_DREP,
                            NULL, 
                            0,
                            &context->m_Context,
                            &obd,
                            &CtxtAttr,
                            &Expiration 
                        );

    if ( (status == SEC_I_COMPLETE_NEEDED) ||
         (status == SEC_I_COMPLETE_AND_CONTINUE) )
    {
        if ( pSecurityInterface->CompleteAuthToken != NULL )
            pSecurityInterface->CompleteAuthToken ( &context->m_Context, &obd );
    }

    switch ( status )
    {
        case SEC_E_OK:
        case SEC_I_COMPLETE_NEEDED:
        case SEC_I_CONTINUE_NEEDED:
        case SEC_I_COMPLETE_AND_CONTINUE:
            break;
        case SEC_E_LOGON_DENIED:
        default:
            // Authorisation failed
            // make sure we don't leak memory
            delete[] (BYTE*)(pToken);
            ob.cbBuffer = 0;
            return NULL;
    }
    
	if (ob.cbBuffer > 0) {
        //
        // Convert local buffer into a java byte array.
        //
		jbyteArray retBuf = env->NewByteArray((unsigned long)ob.cbBuffer);
		env->SetByteArrayRegion(retBuf, 0, (unsigned long)ob.cbBuffer, (const signed char *)pToken);
        // make sure we don't leak memory
        delete[] (BYTE*)(pToken);
		return retBuf;
	} else {
        if (context == NULL ) {
            IllegalStateException(env, "NTLM Authentication failed");
        }
		return NULL;
	}

}

//
// Called to create the NTLM challenge response
//
JNIEXPORT jbyteArray JNICALL Java_net_sourceforge_jtds_util_SSPIJNIClient_prepareSSOSubmit
            (JNIEnv *env, jobject obj, jbyteArray buf, jlong size)
{
    //
    // Obtain saved security context from Thread Local Storage
    //
    Context* context = (Context*)TlsGetValue(tlsIndex);
    if (context == NULL) {
  		IllegalStateException(env, "Unable to retrieve security contex from TLS");
        return NULL;
    }
    //
    // Get the java byte array parameter
    //
    jbyte* newBuf = env->GetByteArrayElements(buf, NULL);

    SecBufferDesc   ibd, obd;
    SecBuffer       ib,  ob;
    SECURITY_STATUS status;
    BYTE*       pToken;        

    // prepare outbound buffer
    ob.BufferType = SECBUFFER_TOKEN;
    ob.cbBuffer   = cbMaxToken;
    pToken     = new BYTE[ob.cbBuffer];
    if ( pToken == NULL ) {
        IllegalStateException(env, "Out of memory creating security token");
        return NULL;
    }
    ob.pvBuffer   = pToken;
    // prepare buffer description
    obd.cBuffers  = 1;
    obd.ulVersion = SECBUFFER_VERSION;
    obd.pBuffers  = &ob;

    // prepare inbound buffer
    ib.BufferType = SECBUFFER_TOKEN;
    ib.cbBuffer   = size;
    ib.pvBuffer   = newBuf;
    // prepare buffer description
    ibd.cBuffers  = 1;
    ibd.ulVersion = SECBUFFER_VERSION;
    ibd.pBuffers  = &ib;

    // prepare our context
    DWORD      CtxtAttr;
    TimeStamp  Expiration;
    //
    // Generate the response to the supplied NTLM challenge
    //
    status =   pSecurityInterface->InitializeSecurityContext ( 
                            &context->m_Credentials,
                            &context->m_Context,
                            NULL,
                            ISC_REQ_REPLAY_DETECT | ISC_REQ_SEQUENCE_DETECT |
                            ISC_REQ_CONFIDENTIALITY | ISC_REQ_DELEGATE, 
                            0,
                            SECURITY_NATIVE_DREP,
                            &ibd, 
                            0,
                            &context->m_Context,
                            &obd,
                            &CtxtAttr,
                            &Expiration 
                        );

    if ( (status == SEC_I_COMPLETE_NEEDED) ||
         (status == SEC_I_COMPLETE_AND_CONTINUE) )
    {
        if ( pSecurityInterface->CompleteAuthToken != NULL )
            pSecurityInterface->CompleteAuthToken ( &context->m_Context, &obd );
    }

    switch ( status )
    {
        case SEC_E_OK:
        case SEC_I_COMPLETE_NEEDED:
        case SEC_I_CONTINUE_NEEDED:
        case SEC_I_COMPLETE_AND_CONTINUE:
            break;
        case SEC_E_LOGON_DENIED:
        default:
            // Authorisation failed
            // make sure we don't leak memory
            delete[] (BYTE*)(pToken);
            ob.cbBuffer = 0;
    }

	if (ob.cbBuffer > 0) {
        //
        // Convert local buffer into a java byte array.
        //
		jbyteArray retBuf = env->NewByteArray((unsigned long)ob.cbBuffer);
		env->SetByteArrayRegion(retBuf, 0, (unsigned long)ob.cbBuffer, (const signed char *)pToken);
        // make sure we don't leak memory
        delete[] (BYTE*)(pToken);
        // Done with context        
        pSecurityInterface->DeleteSecurityContext ( &context->m_Context );
        // And credentials
        pSecurityInterface->FreeCredentialsHandle( &context->m_Credentials);
        TlsSetValue(tlsIndex, NULL);
        delete context;
		return retBuf;
	} else {
        if (context == NULL ) {
            IllegalStateException(env, "NTLM Authentication failed");
        }
		return NULL;
	}
}

