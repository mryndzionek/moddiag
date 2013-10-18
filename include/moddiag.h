/*
 * Copyright © 2012-2013 Mariusz Ryndzionek <mryndzionek@gmail.com>
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
 * You should have received a copy of the GNU General Public License
 * along with . If not, see <http://www.gnu.org/licenses>.
 */

#ifndef _MODDIAG_H_
#define _MODDIAG_H_

#include <modbus/modbus.h>

#include <options.h>
#include <config.h>

//#define DEBUG_PRINT_ENABLED 1  // uncomment to enable DEBUG statements
#if DEBUG_PRINT_ENABLED
#define DEBUG printf
#else
#define DEBUG(format, args...) ((void)0)
#endif

/* Crash the process */
#define __CRASH()    (*(char *)NULL)

/* Generate a textual message about the assertion */
#define __BUG_REPORT( _cond, _format, _args ... ) \
    fprintf( stderr, "%s:%d: Assertion error in function '%s' for condition '%s': " _format "\n", \
    __FILE__, __LINE__, __FUNCTION__, # _cond, ##_args ) && fflush( NULL ) != (EOF-1)

/* Check a condition, and report and crash in case the condition is false */
#define DBG_ASSERT( _cond, _format, _args ... ) \
do { if(!(_cond)) { __CRASH() = __BUG_REPORT( _cond, _format, ##_args ); } } while( 0 )

modbus_t* modbus_init_con(options_t *opt);
void display_16bit(options_t *opt, uint16_t *tab);
void display_8bit(options_t *opt, uint8_t *tab);

#endif

