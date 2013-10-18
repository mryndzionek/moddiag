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

#ifndef _OPTIONS_H_
#define _OPTIONS_H_

#define BUFLEN 1024
#define DEFAULT_RESP_TIMEOUT 50000  //us

#define LEN_EXCEPTION 		1<<0
#define RANGE_EXCEPTION		1<<1

#define MAX_UINT		65535
#define MAX_L_UINT		4294967295LL

#define MAX_INT			32767
#define MIN_INT			-32767

#define MAX_L_INT		2147483647LL
#define MIN_L_INT		-2147483647LL

typedef enum {
	_RC=0,
	_RD,
	_RH,
	_RI,
	_WC,
	_WH,
	_UNDEF
} action_t;

typedef enum {
	_TCP=0,
	_RTU
} connection_t;

typedef struct
{
	char buffer[BUFLEN+1];
	int buflen;
	int cs;
	const char *p;
	// length exception flag
	short ex_flag;

	short inverse;
	short debug;
	struct timeval timeout;

	//connection
	connection_t connection_type;

	//serial
	char device[64];
	int baud;
	uint8_t data_bit;
	uint8_t stop_bit;
	char parity;

	//tcp
	int port;
	char ip[16];

	//action
	action_t action;
	uint16_t address;
	uint16_t count;
	uint16_t index;

	//values
	uint16_t reg_values[20];
	uint8_t coil_values[20];
	
} options_t;

void options_init(options_t *ctx);
void options_execute(options_t *ctx, const char *data, int len);
int options_finish(options_t *ctx);
void options_dump(options_t *ctx);
void options_help();
void options_err_disp(options_t *ctx, const char *cmd);

#endif
