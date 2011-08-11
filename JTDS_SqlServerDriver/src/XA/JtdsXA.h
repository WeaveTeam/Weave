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

#define MAX_THREADS         64          // This limits the number connections
#define EXECUTE_TIMEOUT     300000      // 5 minutes
#define THREAD_TIMEOUT      300000      // 5 minutes
#define COOKIE_SIZE         128         // Normally 80 bytes 
#define MAX_SERVER_ERROR    20000
#define XP_JTDS_ERROR MAX_SERVER_ERROR+100
#define NUM_PARAMS          5
#define LOG_PATH            "c:\\temp\\jtdslog.txt"

/*
 * Indexes of our command mapping
 */
#define XAN_SHUTDOWN 0
#define XAN_OPEN     1
#define XAN_CLOSE    2
#define XAN_START    3
#define XAN_END      4
#define XAN_ROLLBACK 5
#define XAN_PREPARE  6
#define XAN_COMMIT   7
#define XAN_RECOVER  8
#define XAN_FORGET   9
#define XAN_COMPLETE 10
#define XAN_SLEEP    11

/*
 * Flag definitions for the RM switch
*/
#define TMNOFLAGS   0x00000000L     // no resource manager features selected 
#define TMREGISTER  0x00000001L     // resource manager dynamically registers 
#define TMNOMIGRATE 0x00000002L     // resource manager does not support association migration 
#define TMUSEASYNC  0x00000004L     // resource manager supports asynchronous operations 
/*
* Flag definitions for xa_ 
*/
#define TMASYNC     0x80000000L     // perform routine asynchronously
#define TMONEPHASE  0x40000000L     // caller is using one-phase commit optimisation 
#define TMFAIL      0x20000000L     // dissociates caller and marks transaction branch rollback-only 
#define TMNOWAIT    0x10000000L     // return if blocking condition exists
#define TMRESUME    0x08000000L     // caller is resuming association with suspended transaction branch 
#define TMSUCCESS   0x04000000L     // dissociate caller from transaction branch
#define TMSUSPEND   0x02000000L     // caller is suspending, not ending, association 
#define TMSTARTRSCAN 0x01000000L    // start a recovery scan 
#define TMENDRSCAN  0x00800000L     // end a recovery scan 
#define TMMULTIPLE  0x00400000L     // wait for any asynchronous operation 
#define TMJOIN      0x00200000L     // caller is joining existing transaction branch 
#define TMMIGRATE   0x00100000L     // caller intends to perform migration 
/*
* xa_() return codes (resource manager reports to transaction manager)
*/
#define XA_RBBASE 100               // the inclusive lower bound of the rollback codes 
#define XA_RBROLLBACK XA_RBBASE     // the rollback was caused by an unspecified reason 
#define XA_RBCOMMFAIL XA_RBBASE+1   // the rollback was caused by a communication failure 
#define XA_RBDEADLOCK XA_RBBASE+2   // a deadlock was detected 
#define XA_RBINTEGRITY XA_RBBASE+3  // a condition that violates the integrity of the resources was detected 
#define XA_RBOTHER XA_RBBASE+4      // the resource manager rolled back the transaction branch for a reason not on this list 
#define XA_RBPROTO XA_RBBASE+5      // a protocol error occurred in the resource manager 
#define XA_RBTIMEOUT XA_RBBASE+6    // a transaction branch took too long 
#define XA_RBTRANSIENT XA_RBBASE+7  // may retry the transaction branch 
#define XA_RBEND XA_RBTRANSIENT     // the inclusive upper bound of the rollback codes 
#define XA_NOMIGRATE 9              // resumption must occur where suspension occurred 
#define XA_HEURHAZ 8                // the transaction branch may have been heuristically completed 
#define XA_HEURCOM 7                // the transaction branch has been heuristically committed
#define XA_HEURRB 6                 // the transaction branch has been heuristically rolled back 
#define XA_HEURMIX 5                // the transaction branch has been heuristically committed and rolled back 
#define XA_RETRY 4                  // routine returned with no effect and may be reissued 
#define XA_RDONLY 3                 // the transaction branch was read-only and has been committed 
#define XA_OK 0                     // normal execution 
#define XAER_ASYNC -2               // asynchronous operation already outstanding */
#define XAER_RMERR -3               // a resource manager error occurred in the transaction branch */
#define XAER_NOTA -4                // the XID is not valid 
#define XAER_INVAL -5               // invalid arguments were given 
#define XAER_PROTO -6               // routine invoked in an improper context 
#define XAER_RMFAIL -7              // resource manager unavailable 
#define XAER_DUPID -8               // the XID already exists 
#define XAER_OUTSIDE -9             // resource manager doing work outside 

#ifdef _DEBUG
#define TRACE(s) if (fp_log != NULL) fprintf(fp_log, s);
#else
#define TRACE(s)
#endif

/*
 * Thread control block
 */
typedef struct _threadcb {
    volatile int    bInUse;         // Indicates state of thread eg free etc
    int             threadID;       // Windows thread identifier
    int             conId;          // Connection ID owning thread
    int             bOpen;          // Thread has been connected to MSDTC
    int             bRecover;       // Thread used by recover do not free
    HANDLE          evDone;         // Event object for synchronization
	HANDLE          evSuspend;      // Event object for synchronization
    int             xaCmd;          // XA Command to execute
    int             xaRmid;         // Resource manager ID allocated by TM
    int             xaFlags;        // XA Flags for command
    XID             *xid;           // Global transaction ID
    char            *szOpen;        // xa_open ID string
    int             rc;             // Return code from XA function
    char            *szMsg;         // Optional error message
    int             cbCookie;       // Cookie buffer size
    BYTE            *pCookie;       // Returned TX cookie
} THREAD_CB;


/*
 * Forward declarations
 */
static DWORD WINAPI WorkerThread(LPVOID);
static int   AllocateThread(int);
static void  FreeThread(int);
static int   ThreadExecute(THREAD_CB *, SRV_PROC *pSrvProc, int, int, int, BYTE *);
static int   FindThread(int);
static void  ReportError(SRV_PROC *, char *);
static void  XAStartCmd(THREAD_CB *tcb);
