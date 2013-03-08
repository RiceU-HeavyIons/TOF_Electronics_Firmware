; $Id: CANHLP.inc,v 1.1 2007-03-29 15:25:12 jschamba Exp $
;******************************************************************************
;                                                                             *
;    Filename:      CANHLP.inc                                                *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:        J. Schambach                                              *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************

#ifndef __CANHLP_INC           ;Check if inc file already included
#define __CANHLP_INC

#ifndef  HLP_PRIOR_SOURCE
    EXTERN  TofHandleWrite, TofHandleRead
#endif

#endif
