/* $Id$ */
/***********************************************************************
 * This file provides a basic template for writing dsPIC30F trap       *
 * handlers in C language for the C30 compiler                         *
 *                                                                     *
 * Add this file into your MPLAB project. Build your project, program  *
 * the device and run. If any trap occurs during code execution, the   *
 * processor vectors to one of these routines.                         *
 *                                                                     *
 * For additional information about dsPIC architecture and language    *
 * tools, refer to the following documents:                            *
 *                                                                     *
 * MPLAB C30 Compiler User's Guide                        : DS51284    *
 * dsPIC 30F MPLAB ASM30, MPLAB LINK30 and Utilites                    *
 *                                           User's Guide : DS51317    *
 * Getting Started with dsPIC DSC Language Tools          : DS51316    *
 * dsPIC 30F Language Tools Quick Reference Card          : DS51322    *
 * dsPIC 30F 16-bit MCU Family Reference Manual           : DS70046    *
 * dsPIC 30F General Purpose and Sensor Families                       *
 *                                           Data Sheet   : DS70083    *
 * dsPIC 30F/33F Programmer's Reference Manual            : DS70157    *
 *                                                                     *
 * Template file has been compiled with MPLAB C30 v2.04.               *
 *                                                                     *
 ***********************************************************************
 *                                                                     *
 *    Author:                                                          *
 *    Company:                                                         *
 *    Filename:       traps.c                                          *
 *    Date:           08/07/2006                                       *
 *    File Version:   2.00                                             *
 *    Devices Supported:  All PIC24F,PIC24H,dsPIC30F,dsPIC33F devices  *
 *                                                                     *
 **********************************************************************/

#if defined(__dsPIC33F__)
#include "p33FJ256GP710.h"
#elif defined(__PIC24H__)
#include "p24hxxxx.h"
#endif


/* ****************************************************************
* Standard Exception Vector handlers if ALTIVT (INTCON2<15>) = 0  *
*                                                                 *
* Not required for labs but good to always include                *
******************************************************************/
void _ISR __attribute__((no_auto_psv))_OscillatorFail(void)
{

        INTCON1bits.OSCFAIL = 0;
        while(1);
}

void _ISR __attribute__((no_auto_psv))_AddressError(void)
{

        INTCON1bits.ADDRERR = 0;
        while(1);
}

void _ISR __attribute__((no_auto_psv))_StackError(void)
{

        INTCON1bits.STKERR = 0;
        while(1);
}

void _ISR __attribute__((no_auto_psv))_MathError(void)
{

        INTCON1bits.MATHERR = 0;
        while(1);
}




/* ****************************************************************
* Alternate Exception Vector handlers if ALTIVT (INTCON2<15>) = 1 *
*                                                                 *
* Not required for labs but good to always include                *
******************************************************************/
void _ISR __attribute__((no_auto_psv))_AltOscillatorFail(void)
{

        INTCON1bits.OSCFAIL = 0;
        while(1);
}

void _ISR __attribute__((no_auto_psv))_AltAddressError(void)
{

        INTCON1bits.ADDRERR = 0;
        while(1);
}

void _ISR __attribute__((no_auto_psv))_AltStackError(void)
{

        INTCON1bits.STKERR = 0;
        while(1);
}

void _ISR __attribute__((no_auto_psv))_AltMathError(void)
{

        INTCON1bits.MATHERR = 0;
        while(1);
}



