/*
 * jTDS JDBC Driver for Microsoft SQL Server and Sybase
 * Copyright (C) 2004 The jTDS Project
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
 * --- How to compile this code.
 *
 * 1. You will need a Microsoft compatible compiler such as Visual C++ 6.
 * 2. You will need a copy of the Microsoft Platform SDK to obtain the
 *    required header files and libraries.
 * 3. The code must be linked with xolehlp.lib, xaswitch.lib and opends60.lib.
 */

/*
 * --- How to install this code.
 *
 * 1. Copy the JtdsXA.dll file into the SQL Server binary directory
 *    e.g. C:\Program Files\Microsoft SQL Server\MSSQL\Binn.
 * 2. Log on to the SQL Server as administrator and execute the following
 *    statements:
 *    sp_addextendedproc 'xp_jtdsxa', 'jtdsXA.dll'
 *    go
 *    grant execute on xp_jtdsxa to public
 *    go
 *
 * The DLL can be unloaded without restarting the SQL Server by executing
 * the following command:
 *    dbcc JtdsXA(free)
 */

/*
 * --- Principle of operation.
 *
 * First a caveat. The Microsoft documentation in this area is very poorly
 * organised and incomplete. This code is the result of a lot of guesswork
 * and experimentation. By their very nature distributed transactions and
 * supporting software components are very difficult to test completely.
 *
 * Please DO NOT use this code in any business critical application until
 * you have satisfied yourself that it works correctly. You have been warned!
 *
 * The Microsoft Distributed Transaction Coordinator (DTC) can act as an XA
 * compatible resource manager proxy for SQL Server as it implements the
 * required XA Switch routines such as xa_start, xa_end etc. The XA
 * transactions are internally mapped to Microsoft's proprietary transaction
 * protocol.
 *
 * The DTC requires that each transaction runs on its own Windows thread of
 * execution and whilst that is easy to achieve in an external server process,
 * it is more problematical in an SQL Server extended procedure DLL. This is
 * because SQL Server will call the extended procedure on it's own thread but
 * this thread will not necessarily have a one to one correspondence with the
 * external JDBC connection. Therefore a more sophisticated solution is
 * required to achieve the correct association in the DTC between a Windows
 * thread and the XA transaction.
 *
 * In this implementation a pool of worker threads is used to manage each
 * XA connection from xa_open through to xa_close.
 * This is a reasonably complex solution and hopefully there is someone out
 * there who knows of a better way to achieve the same result.
 *
 * There is a further consideration which, is the need to prevent threads
 * being orphaned by their associated JDBC connection failing before it can
 * execute an xa_close. The approach taken here is to allow threads to
 * timeout and be reused after a period of time. This is only possible if a
 * transaction is not in progress or if the xa_recover command has not been
 * executed. This approach should ensure that if connections crash the worker
 * threads will still be reused.
 *
 * The final piece of the puzzle is that, having allocated a MTS transaction
 * to the external XA transaction, we need a way of telling the SQL server to
 * enlist on this transaction. This is achieved by exporting an MTS transaction
 * cookie, sending it to the JDBC driver and then passing it back once more to
 * the SQL Server in a special TDS packet. This is the equivalent of the ODBC
 * SQLSetConnectOption  SQL_COPT_SS_ENLIST_IN_DTC method.
 *
 * Some final comments on this XA implementation are in order.
 *
 * Starting from SQL Server 7, Microsoft introduced the User Mode Scheduler (UMS)
 * to SQL Server. This component attempts to keep thread scheduling out of the
 * kernel to boost performance and make SQL server more scalable. This is largely
 * achieved by using cooperative multi tasking on a limited number of threads
 * rather than allowing the kernel to pre-emptively multi task.
 *
 * As Microsoft cannot rely on an extended procedure cooperatively multitasking,
 * the UMS has to allocate a normal thread to the session for the purposes of
 * executing the extended procedure.
 * This has the unfortunate result of disrupting the UMS's ability to manage
 * scheduling and leads to a drop in performance and scalability.
 *
 * This is one of the reasons why Microsoft has been steadily deprecating more and
 * more of the open data services API used by extended procedures. There is
 * therefore no guarantee that extended procedures will be supported much longer
 * especially as in SQL 2005 procedures can be written in any of the managed .NET
 * languages.
 *
 * The thread performance issue is further impacted in this application by the need
 * to schedule additional threads to host transactions. Although the extended procedure
 * approach leads to a simple implementation from the JDBC point of view, it is not
 * likely to be as efficient or scalable as the dedicated external server process used
 * by some of the commercial drivers.
 *
 * The final obvious message on performance is that distributed transactions are very
 * expensive to manage when compared to local transactions and should only be used when
 * absolutely necessary.
 */

#define INITGUID
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>
#include <process.h>
#include <srv.h>
#include <txdtc.h>
#include <xolehlp.h>
#include "JtdsXA.h"

/*
 * Shared variables accessed by all threads
 */
static HANDLE	    hThread[MAX_THREADS];   // Table of thread handles
static THREAD_CB    threadCB[MAX_THREADS];  // Table of thread control blocks
static char         szOpen[256];            // XA_OPEN string
static volatile int nThreads = 0;	        // Number of threads in pool
static CRITICAL_SECTION csThreadPool;		// Critical section to synch access to pool
static int          connectionId = 0x7F000000; // XA Connection ID

#ifdef _DEBUG
static FILE         *fp_log = NULL;         // Trace log file
#endif

/*
 * XA Switch structure in DTC Proxy MSDTCPRX.DLL
 */
extern xa_switch_t  msqlsrvxa1;

/*
 * This function is entered when the DLL is loaded and unloaded.
 * Ideally the worker threads should execute and terminate tidily
 * unfortunately DLLMain is protected by a mutex and there is
 * no way that we can wait for the child threads to die as they will
 * not be able to reenter this routine.
 * We get round this by forcibly terminating the threads.
 * All handles are closed to avoid resource leaks when this dll
 * is unloaded by the DBCC JtdsXA(free) command.
 */
BOOL WINAPI DllMain( HINSTANCE hinstDLL,  // handle to DLL module
                     DWORD fdwReason,     // reason for calling function
                     LPVOID lpvReserved)  // reserved
{
    int i;

    switch (fdwReason) {

        case DLL_PROCESS_ATTACH:
            InitializeCriticalSection(&csThreadPool);
        break;

        case DLL_PROCESS_DETACH:
            TRACE("Process Detach\n");
            if (nThreads > 0) {
                for (i = 0; i < nThreads; i++) {
                    TerminateThread(hThread, 0);
                    // Free handles
                    CloseHandle(threadCB[i].evDone);
                    CloseHandle(threadCB[i].evSuspend);
                    CloseHandle(hThread[i]);
                }
            }
            DeleteCriticalSection(&csThreadPool);
            TRACE("JtdsXA unloaded\n");
#ifdef _DEBUG
            if (fp_log != NULL) {
                fclose(fp_log);
            }
#endif
        break;
    }
    return TRUE;
}

/*
 * Defining this function is recommended by Microsoft to allow the
 * server to check for version compatibility.
 */
__declspec(dllexport) ULONG __GetXpVersion()
{
    return ODS_VERSION;
}

/*
 * Main entry point for the extended stored procedure.
 * The SQL signature is:
 * exec @retval = xp_jtdsxa @cmd int, @id int, @rmid int,
 *                            @flags int, @param varbinary(8000) output
 *
 */
__declspec(dllexport) SRVRETCODE xp_jtdsxa(SRV_PROC *pSrvProc)
{
    int  xaCmd   = 0;       // XA Command to execute
    int  xaRmid  = 0;       // Resource Manager ID from TM
    int  conId   = 0;       // Connection ID
    int  xaFlags = 0;       // XA Flags
    BYTE *xid    = NULL;    // XID or xa_open String
    long cbXid   = 0;       // Length of data in XID

    int  thread;            // Index into thread table
    int  rc  = XAER_RMFAIL; // Default return code
    int  i;

    BYTE bType;             // TDS data type
    long cbMaxLen;          // Maximum length of variable types
    long cbActualLen;       // Actual length of parameter
    BOOL fNull;             // True if parameter was null

    //
    // Check the parameter count.
    //
    if (srv_rpcparams(pSrvProc) != NUM_PARAMS) {
        // Send error message and return
        //
        ReportError(pSrvProc, "xp_jtdsxa: wrong number of parameters");
        return rc;
    }

    //
    // Validate parameter types
    //
    for (i = 0; i < NUM_PARAMS-1; i++) {
        // Use srv_paraminfo to get data type and length information.
        if (FAIL == srv_paraminfo(pSrvProc, i+1, &bType, &cbMaxLen,
            &cbActualLen, NULL, &fNull))
        {
            ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed");
            return rc;
        }
        // These should int input params
        if (bType != SRVINTN && bType != SRVINT4) {
            ReportError(pSrvProc, "xp_jtdsxa: integer parameter expected");
            return rc;
        }
    }

    // Use srv_paraminfo to get data type and length information.
    if (FAIL == srv_paraminfo(pSrvProc, NUM_PARAMS, &bType, &cbMaxLen,
	        &cbActualLen, NULL, &fNull))
    {
        ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed");
        return rc;
    }
    // Should be varbinary output
    if (bType != SRVVARBINARY && bType != SRVBIGVARBINARY) {
        ReportError(pSrvProc, "xp_jtdsxa: last parameter should be varbinary");
        return rc;
    }
    // Should be a return (OUTPUT) parameter
    if ((srv_paramstatus(pSrvProc, NUM_PARAMS) & SRV_PARAMRETURN) == FAIL) {
        ReportError(pSrvProc, "xp_jtdsxa: last parameter should be output");
    return rc;
    }
    // Check that input data length is less than 256
    if (cbActualLen > 255) {
        ReportError(pSrvProc, "xp_jtdsxa: last parameter is longer than 255 bytes");
        return rc;
    }

    //
    // Extract input parameters
    //
    // @cmd
    if (FAIL == srv_paraminfo(pSrvProc, 1, &bType, &cbMaxLen,
            &cbActualLen, (BYTE*)&xaCmd, &fNull))
    {
        ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed on @cmd");
        return rc;
    }
    // @id
    if (FAIL == srv_paraminfo(pSrvProc, 2, &bType, &cbMaxLen,
            &cbActualLen, (BYTE*)&conId, &fNull))
    {
        ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed on @id");
        return rc;
    }
    // @rmid
    if (FAIL == srv_paraminfo(pSrvProc, 3, &bType, &cbMaxLen,
            &cbActualLen, (BYTE*)&xaRmid, &fNull))
    {
        ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed on @rmid");
        return rc;
    }
    // @flags
    if (FAIL == srv_paraminfo(pSrvProc, 4, &bType, &cbMaxLen,
            &cbActualLen, (BYTE*)&xaFlags, &fNull))
    {
        ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed on @flags");
        return rc;
    }
    // @param
    xid = (BYTE*)malloc(256);
    if (xid == NULL) {
        ReportError(pSrvProc, "xp_jtdsxa: unable to allocate buffer memory");
        return rc;
    }
    memset(xid, 0, 256); // Zero fill as XID may be truncated

    if (FAIL == srv_paraminfo(pSrvProc, 5, &bType, &cbMaxLen,
            &cbXid, xid, &fNull))
    {
        ReportError (pSrvProc, "xp_jtdsxa: srv_paraminfo failed on @param");
        free(xid);
        return rc;
    }
    //
    // Keep things tidy by setting the output value to null
    //
    srv_paramsetoutput(pSrvProc, NUM_PARAMS, NULL, 0, TRUE);

    //
    // Allocate new connection ID if executing open
    //
    if (xaCmd == XAN_OPEN) {
#ifdef _DEBUG
        if (conId != 0 && fp_log == NULL) {
            // Enable tracing
            fp_log = fopen(LOG_PATH, "wt");
            setvbuf(fp_log, NULL, _IONBF, 0);
        }
#endif
        if (szOpen[0] == '\0') {
            // First open call so cache open string
            EnterCriticalSection(&csThreadPool);
            memcpy(szOpen, xid, cbXid);
            LeaveCriticalSection(&csThreadPool);
        }
        // Allocate a new ID for this connection
        EnterCriticalSection(&csThreadPool);
        conId = connectionId++;
        LeaveCriticalSection(&csThreadPool);
    } else {
        // Check connectionId format
        if ((conId & 0x7F000000) != 0x7F000000) {
            ReportError (pSrvProc, "xp_jtdsxa: Connection ID is invalid");
            free(xid);
            return rc;
       }
    }

    //
    // Now find or allocate thread
    //
    thread = FindThread(conId);
    if (thread < 0) {
        // Need to allocate a new one
        thread = AllocateThread(conId);
        if (thread < 0) {
            ReportError(pSrvProc,
                  "xp_jtdsxa: xa_open - Maximum number of XA connections in use");
            free(xid);
            return rc;
        }
    }
    //
    // Switch execution to the correct XA routine
    //
    switch (xaCmd) {
    //
    // xa_open - Connect the worker thread to the MSDTC
    //
        case XAN_OPEN:
            TRACE("cmd=xa_open("); TRACE((char*)xid);TRACE(")\n");
            if (!threadCB[thread].bOpen) {
                threadCB[thread].szOpen = (char*)xid;
                rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, NULL);
            } else {
                rc = XA_OK;
            }
            //
            // Return thread ID to user
            //
            if (rc == XA_OK) {
                // Set the output parameter to the value of the thread ID.
                srv_paramsetoutput(pSrvProc, NUM_PARAMS, (char*)&conId, sizeof(int), FALSE);
            }
        break;
        //
        // xa_close - Disconnect the worker thread from the MSTDC
        //
        case XAN_CLOSE:
            TRACE("cmd=xa_close\n");
            threadCB[thread].szOpen     = (char*)xid;
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, NULL);
            FreeThread(thread);
        break;
        //
        // xa_start - MSDTC requires each transaction to execute on
        // it's own Windows thread. This requirement is satisfied by
        // allocating a pooled worker thread for the duration of the
        // transaction.
        //
        case XAN_START:
            TRACE("cmd=xa_start\n");
            threadCB[thread].pCookie    = (BYTE *)malloc(COOKIE_SIZE);
            threadCB[thread].cbCookie   = COOKIE_SIZE;
            threadCB[thread].szMsg     = NULL;
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, xid);
            if (threadCB[thread].szMsg != NULL) {
                ReportError(pSrvProc, threadCB[thread].szMsg);
            } else
            if (cbMaxLen < threadCB[thread].cbCookie) {
                ReportError(pSrvProc, "xp_jtdsxa: xa_start - Output parameter is too short");
            } else {
                // Set the output parameter to the value of the OLE Cookie.
                srv_paramsetoutput(pSrvProc, NUM_PARAMS, threadCB[thread].pCookie,
                                        threadCB[thread].cbCookie, FALSE);
            }
            free(threadCB[thread].pCookie);
        break;
        //
        // xa_end - Use the XID to locate the worker thread that we started the
        // transaction on then get it to execute xa_end.
        //
        case XAN_END:
            TRACE("cmd=xa_end\n");
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, xid);
        break;
        //
        // xa_prepare - Use the XID to locate the worker thread that we started the
        // transaction on then get it to execute xa_prepare.
        //
        case XAN_PREPARE:
            TRACE("cmd=xa_prepare\n");
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, xid);
        break;
        //
        // xa_rollback - Use the XID to locate the worker thread that we started the
        // transaction on then get it to execute xa_rollback.
        // Following this call the worker thread is freed up for use in processing
        // another transaction.
        //
        case XAN_ROLLBACK:
            TRACE("cmd=xa_rollback\n");
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, xid);
        break;
        //
        // xa_commit - Use the XID to locate the worker thread that we started the
        // transaction on then get it to execute xa_commit.
        // Following this call the worker thread is freed up for use in processing
        // another transaction.
        //
        case XAN_COMMIT:
            TRACE("cmd=xa_commit\n");
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, xid);
	    break;
        //
        // Ask the MSTDC to return a list of uncompleted transaction IDs.
        // The complete list is sent back as a result set
        //
        case XAN_RECOVER:
            TRACE("cmd=xa_recover\n");
            xid = (BYTE*)malloc(sizeof(XID));
            if (xid == NULL) {
                rc = XAER_RMFAIL;
                ReportError(pSrvProc, "xp_jtdsxa: Out of memory allocating XID buffer");
                break;
            }
            //
            // Describe the single column in result set as XID BINARY(140)
            //
            if (0 == srv_describe(pSrvProc,
                                  1,
                                  "XID",
                                  SRV_NULLTERM,
                                  SRVBINARY,
                                  sizeof(XID),
                                  SRVBINARY,
                                  sizeof(XID),
                                  xid))
            {
                rc = XAER_RMFAIL;
                ReportError(pSrvProc, "xp_jtdsxa: Failed to descibe XID result set");
                break;
            }
            i = 0;
            //
            // Obtain first XID to recover
            //
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, TMSTARTRSCAN, xid);
            if (rc < 0) {
                break;
            }
            threadCB[thread].bRecover = TRUE;
            //
            // Now loop to obtain remaining XIDs
            // TODO: this is not very effeicient should ask MSTDC for
            // XIDs in each call
            //
            while (rc > 0) {
                if (FAIL == srv_sendrow(pSrvProc)) {
                    break;
                }
                i++;
                rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, TMNOFLAGS, xid);
            }
            srv_senddone(pSrvProc, (SRV_DONE_COUNT | SRV_DONE_MORE), 0, i);
            rc = i;
        break;
        //
        // Ask the MSDTC to forget a heuristically completed transaction.
        //
        case XAN_FORGET:
            TRACE("cmd=xa_forget\n");
            rc = ThreadExecute(&threadCB[thread], pSrvProc, xaCmd, xaRmid, xaFlags, xid);
        break;
        //
        // Wait for an asynchronous operation to complete.
        // As Java does not seem to require asynchronous operations this
        // is just a dummy operation.
        //
        case XAN_COMPLETE:
            TRACE("cmd=xa_complete\n");
            rc = XAER_PROTO;
        break;
        default:
            ReportError(pSrvProc, "xp_jtdsxa: Invalid XA command");
            break;
    }
    if (xid != NULL) {
        free(xid);
    }
    return rc;
}

/*
 * Invoke the XA command on the worker thread.
 */
int ThreadExecute(THREAD_CB *tcb, SRV_PROC *pSrvProc,
                  int xaCmd, int xaRmid, int xaFlags, BYTE *xid)
{
    int rc;
    //
    // Check that this worker thread is connected to the MSDTC
    //
    if (!tcb->bOpen && xaCmd != XAN_OPEN) {
        tcb->szOpen  = szOpen;
        rc = ThreadExecute(tcb, pSrvProc, XAN_OPEN, xaRmid, TMNOFLAGS, NULL);
        if (rc != XA_OK) {
            return rc;
        }
        tcb->bOpen = TRUE;
    }
    tcb->xaCmd   = xaCmd;
    tcb->xaRmid  = xaRmid;
    tcb->xaFlags = xaFlags;
    tcb->xid     = (XID *)xid;
    // unsignal the event that this thread will sleep on
    ResetEvent(tcb->evDone);
    // Signal the event that the worker thread is sleeping on
    SetEvent(tcb->evSuspend);
    // Wait for worker thread to execute.
    if (WaitForSingleObject(tcb->evDone, EXECUTE_TIMEOUT) != WAIT_OBJECT_0) {
        ReportError(pSrvProc, "xp_jtdsxa: Worker Thread timed out executing command");
        tcb->conId = 0; // This will stop this thread being used again
        return XAER_RMFAIL;
    }
    return tcb->rc;
}

/*
 * Locate the thread allocated to this connection.
 */
int FindThread(int conId)
{
    int i;
    int nt = -1;
    TRACE("FindThread()\n");
    EnterCriticalSection(&csThreadPool);

    for (i = 0; i < nThreads; i++) {
        // Look for this connection's thread
        if (threadCB[i].bInUse == TRUE && threadCB[i].conId == conId) {
            nt = i;
            break;
        }
    }

    LeaveCriticalSection(&csThreadPool);
    return nt;
}

/*
 * Locate a free worker thread or create a new one.
 * This routine is synchronized by using a critical
 * section to protect the thread table.
 */
int AllocateThread(int conId)
{
    int i;
    int nt = -1;
    TRACE("GetWorkerThread()\n");
    EnterCriticalSection(&csThreadPool);

    for (i = 0; i < nThreads; i++) {
        // Look for free thread
        if (threadCB[i].bInUse == FALSE) {
            threadCB[i].bInUse = TRUE;
            threadCB[i].szMsg  = NULL;
            threadCB[i].conId  = conId;
            threadCB[nThreads].bRecover= FALSE;
            nt = i;
            break;
        }
    }

    if (nt < 0 && nThreads < MAX_THREADS) {
        // No threads so create one
        threadCB[nThreads].bInUse  = TRUE;
        threadCB[nThreads].szMsg   = NULL;
        threadCB[nThreads].conId   = conId;
        threadCB[nThreads].bRecover= FALSE;
        threadCB[nThreads].evDone  = CreateEvent(NULL, TRUE, FALSE, NULL);
        ResetEvent(threadCB[nThreads].evSuspend);
        threadCB[nThreads].evSuspend = CreateEvent(NULL, TRUE, FALSE, NULL);
#ifdef _DEBUG
        hThread[nThreads] =
            (HANDLE)_beginthreadex(NULL,
                                   0,
                                   (LPTHREAD_START_ROUTINE)WorkerThread,
                                   &threadCB[nThreads],
                                   0,
                                   &threadCB[nThreads].threadID);
#else
        hThread[nThreads] =
           (HANDLE)CreateThread(NULL,
                                0,
                                (LPTHREAD_START_ROUTINE)WorkerThread,
                                &threadCB[nThreads],
                                0,
                                &threadCB[nThreads].threadID);
#endif
        if (hThread[nThreads] != NULL) {
            nt = nThreads++;
        }
        TRACE("GetWorkerThread() - New thread allocated\n");
    }
    LeaveCriticalSection(&csThreadPool);
    return nt;
}

/*
 * Free a thread.
 */
void FreeThread(int nThread)
{
    TRACE("FreeThread()\n");
    threadCB[nThread].bInUse = FALSE;
    threadCB[nThread].conId  = 0;
}

/*
 * Report an error message back to the user in a TDS error
 * packet.
 */
void ReportError(SRV_PROC *pSrvProc, char *szErrorMsg)
{
    TRACE("ReportError('");
    TRACE(szErrorMsg);
    TRACE("')\n");
    srv_sendmsg(pSrvProc, SRV_MSG_ERROR, XP_JTDS_ERROR, SRV_INFO, 1,
                NULL, 0, (DBUSMALLINT) 0,
                szErrorMsg,
                SRV_NULLTERM);

    srv_senddone(pSrvProc, (SRV_DONE_ERROR | SRV_DONE_MORE), 0, 0);
}

/*
 * Worker thread created to handle each XA connection.
 * The Thread sleeps on an Event object in the control block
 * until released by the controlling thread to execute the xa function.
 */
DWORD WINAPI WorkerThread(LPVOID lpParam)
{
    THREAD_CB *tcb = (THREAD_CB *)lpParam;
    int cmd;

    TRACE("WorkerThread created\n");

    // Initially suspended until released by creating thread
    WaitForSingleObject(tcb->evSuspend, INFINITE);

    while (tcb->xaCmd != XAN_SHUTDOWN) {
        cmd = tcb->xaCmd;

        // Unsignal event ready for next sleep
        ResetEvent(tcb->evSuspend);
        //
        // Now execute requested command
        //
        switch (cmd) {
            // xa_open
            case XAN_OPEN:
                TRACE("WorkerThread - executing open\n");
                tcb->rc = (msqlsrvxa1.xa_open_entry)(tcb->szOpen, tcb->xaRmid, tcb->xaFlags);
                if (tcb->rc == XA_OK) {
                    tcb->bOpen = TRUE;
                }
                break;
            // xa_close
            case XAN_CLOSE:
                TRACE("WorkerThread - executing close\n");
                if (tcb->bOpen) {
                    tcb->rc = (msqlsrvxa1.xa_close_entry)(tcb->szOpen, tcb->xaRmid, tcb->xaFlags);
                    tcb->bOpen = FALSE;
                } else {
                    tcb->rc = XA_OK;
                }
                break;
            // xa_start
            case XAN_START:
                TRACE("WorkerThread - executing start\n");
                XAStartCmd(tcb);
                break;
                // xa_end
            case XAN_END:
                TRACE("WorkerThread - executing end\n");
                tcb->rc = (msqlsrvxa1.xa_end_entry)(tcb->xid, tcb->xaRmid, tcb->xaFlags);
                break;
            // xa_prepare
            case XAN_PREPARE:
                TRACE("WorkerThread - executing prepare\n");
                tcb->rc = (msqlsrvxa1.xa_prepare_entry)(tcb->xid, tcb->xaRmid, tcb->xaFlags);
                break;
            // xa_rollback
            case XAN_ROLLBACK:
               TRACE("WorkerThread - executing rollback\n");
                tcb->rc = (msqlsrvxa1.xa_rollback_entry)(tcb->xid, tcb->xaRmid, tcb->xaFlags);
                break;
            // xa_commit
            case XAN_COMMIT:
                TRACE("WorkerThread - executing commit\n");
                tcb->rc = (msqlsrvxa1.xa_commit_entry)(tcb->xid, tcb->xaRmid, tcb->xaFlags);
                break;
            // xa_recover
            case XAN_RECOVER:
                TRACE("WorkerThread - executing recover\n");
                tcb->rc = (msqlsrvxa1.xa_recover_entry)(tcb->xid, 1, tcb->xaRmid, tcb->xaFlags);
                break;
            // xa_forget
            case XAN_FORGET:
                TRACE("WorkerThread - executing forget\n");
                tcb->rc = (msqlsrvxa1.xa_forget_entry)(tcb->xid, tcb->xaRmid, tcb->xaFlags);
                break;

        }
        // Free the sleeping controlling thread
        SetEvent(tcb->evDone);
        // Suspend until released by controlling thread
        if (!tcb->bRecover && (cmd == XAN_COMMIT || cmd == XAN_ROLLBACK || cmd == XAN_OPEN)) {
            // Sleep with timeout to recover thread if possible
            if (WAIT_OBJECT_0 != WaitForSingleObject(tcb->evSuspend, THREAD_TIMEOUT)) {
                if (cmd != tcb->xaCmd) {
                    // Race condition sleep up at same time as executed
                    continue;
                }
                TRACE("WorkerThread logged out\n");
                (msqlsrvxa1.xa_close_entry)(szOpen, tcb->xaRmid, TMNOFLAGS);
                tcb->bOpen  = FALSE;
                tcb->conId  = 0;
                tcb->bInUse = FALSE;
                // Unsignal event ready for next sleep
                ResetEvent(tcb->evSuspend);
                // Sleep until woken by controlling thread
                WaitForSingleObject(tcb->evSuspend, INFINITE);
            }
        } else {
            // Sleep until woken by controlling thread
            WaitForSingleObject(tcb->evSuspend, INFINITE);
        }
    }
    //
    // Thread is closing down
   //
   TRACE("WorkerThread shutdown\n");
   return 0;
}

/*
 * Issue an XA Start transaction command.
 * Any OLE errors are returned as a string in the thread
 * control block so that they can be passed to the client
 * in an SQL error reply.
 * This OLE stuff is much easier to do in C++ but this
 * DLL has been written in C for maximum portability.
 */
void XAStartCmd(THREAD_CB *tcb)
{
    IXATransLookup                  *pXATransLookup;
    ITransaction                    *pTransaction;
    ITransactionExportFactory       *pTranExportFactory;
    ITransactionImportWhereabouts   *pTranWhere;
    ITransactionExport              *pTranExport;
    BYTE    whereabouts[128];
    ULONG   cbWhereabouts;
    HRESULT	hr;
    //
    // Register the XID with MSDTC
    //
    tcb->rc = (msqlsrvxa1.xa_start_entry)(tcb->xid, tcb->xaRmid, tcb->xaFlags);
    if (tcb->rc != XA_OK) {
        return;
    }
    //
    // Now comes the tricky bit, we need to obtain the OLE transaction ID
    // so that we can pass it back to the driver which in turn will pass
    // it to the SQL Server. This will allow us to enlist the SQL server
    // in the transaction in the same way as the ODBC SQLSetConnectOption
    // SQL_COPT_SS_ENLIST_IN_DTC.
    //
    // Obtain the IXATransLookup interface
    // by calling DtcGetTransactionManager()
    //
    hr = DtcGetTransactionManagerC(
                                    NULL,
                                    NULL,
                                    &IID_IXATransLookup,
                                    0,
                                    0,
                                    NULL,
                                    (void **)&pXATransLookup
                                   );

    if (FAILED(hr))
    {
        tcb->szMsg = "xp_jtdsxa: DtcGetTransactionManager failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }
    //
    // Obtain the OLE transaction that has been mapped to our XID.
    //
    pXATransLookup->lpVtbl->Lookup(pXATransLookup, &pTransaction);
    if (FAILED (hr))
    {
        hr = pXATransLookup->lpVtbl->Release(pXATransLookup);
        tcb->szMsg = "xp_jtdsxa: IXATransLookup->Lookup() failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }
    //
    // Now obtain the ITransactionImportWhereabouts interface.
    // We need this one to obtain a whereabouts structure for use
    // in exporting the transaction cookie.
    //
    hr = DtcGetTransactionManagerC(
                                    NULL,
                                    NULL,
                                    &IID_ITransactionImportWhereabouts,
                                    0,
                                    0,
                                    NULL,
                                    (void **)&pTranWhere
                                  );
    if (FAILED (hr))
    {
        pTransaction->lpVtbl->Release(pTransaction);
        pXATransLookup->lpVtbl->Release(pXATransLookup);
        tcb->szMsg = "xp_jtdsxa: ITransactionImportWhereabouts failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }
    //
    // Now obtain the ITransactionExportFactory interface.
    // We need this to create an ITransactionExport interface
    // which we will use to obtain the OLE transaction cookie.
    //
    hr = DtcGetTransactionManagerC(
                                    NULL,
                                    NULL,
                                    &IID_ITransactionExportFactory,
                                    0,
                                    0,
                                    NULL,
                                    (void **)&pTranExportFactory
                                  );
    if (FAILED (hr))
    {
        pTranWhere->lpVtbl->Release(pTranWhere);
        pTransaction->lpVtbl->Release(pTransaction);
        pXATransLookup->lpVtbl->Release(pXATransLookup);
        tcb->szMsg = "xp_jtdsxa: ITransactionExportFactory failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }
    //
    // Now obtain the whereabouts structure.
    //
    hr = pTranWhere->lpVtbl->GetWhereabouts(pTranWhere,
                                            sizeof(whereabouts),
                                            whereabouts,
                                            &cbWhereabouts);
    if (FAILED (hr))
    {
        pTranExportFactory->lpVtbl->Release(pTranExportFactory);
        pTranWhere->lpVtbl->Release(pTranWhere);
        pTransaction->lpVtbl->Release(pTransaction);
        pXATransLookup->lpVtbl->Release(pXATransLookup);
        tcb->szMsg = "xp_jtdsxa: ITransactionImportWhereabouts->get failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }
    //
    // Now create the ITransactionExport interface
    //
    hr = pTranExportFactory->lpVtbl->Create(pTranExportFactory,
                                            cbWhereabouts,
                                            whereabouts,
                                            &pTranExport);
    if (FAILED (hr))
    {
        pTranExportFactory->lpVtbl->Release(pTranExportFactory);
        pTranWhere->lpVtbl->Release(pTranWhere);
        pTransaction->lpVtbl->Release(pTransaction);
        pXATransLookup->lpVtbl->Release(pXATransLookup);
        tcb->szMsg = "xp_jtdsxa: ITransactionExportFactory->create failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }

    //
    // Marshal the transaction for export and obtain
    // the size of the cookie to be exported
    //
    hr  = pTranExport->lpVtbl->Export(pTranExport,
                                      (IUnknown *)pTransaction,
                                      &tcb->cbCookie);
    if (FAILED (hr) || tcb->cbCookie > COOKIE_SIZE)
    {
        pTranExport->lpVtbl->Release(pTranExport);
        pTranExportFactory->lpVtbl->Release(pTranExportFactory);
        pTranWhere->lpVtbl->Release(pTranWhere);
        pTransaction->lpVtbl->Release(pTransaction);
        pXATransLookup->lpVtbl->Release(pXATransLookup);
        if (FAILED(hr)) {
            tcb->szMsg = "xp_jtdsxa: ITransactionExport->Export failed";
        } else {
            tcb->szMsg = "xp_jtdsxa: Export transaction cookie failed, buffer too smalll";
        }
        tcb->rc = XAER_RMFAIL;
        return;
    }

    //
    // Now obtain the OLE transaction cookie.
    //
    hr = pTranExport->lpVtbl->GetTransactionCookie( pTranExport,
                                                    (IUnknown *)pTransaction,
                                                    tcb->cbCookie,
                                                    tcb->pCookie,
                                                    &tcb->cbCookie);
    if (FAILED (hr))
    {
        pTranExport->lpVtbl->Release(pTranExport);
        pTranExportFactory->lpVtbl->Release(pTranExportFactory);
        pTranWhere->lpVtbl->Release(pTranWhere);
        pTransaction->lpVtbl->Release(pTransaction);
        pXATransLookup->lpVtbl->Release(pXATransLookup);
        tcb->szMsg = "xp_jtdsxa: ITransactionExport->GetTransactionCookie failed";
        tcb->rc = XAER_RMFAIL;
        return;
    }
    //
    // Free the OLE handles
    //
    pTranExport->lpVtbl->Release(pTranExport);
    pTranExportFactory->lpVtbl->Release(pTranExportFactory);
    pTranWhere->lpVtbl->Release(pTranWhere);
    pTransaction->lpVtbl->Release(pTransaction);
    pXATransLookup->lpVtbl->Release(pXATransLookup);
    return;
}
