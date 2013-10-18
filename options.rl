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

#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <errno.h>

#include "moddiag.h"
#include "options.h"

const char usage[] =
		"  Where:\n"
		"  <action> - ((rc|rd|rh|ri):<address>[:<count>])|((wc|wh):<address>:<values>)\n"
		"    rc - read coil(s) (fc = 0x01)\n"
		"    rd - read discrete input(s) (fc = 02)\n"
		"    rh - read holding register(s) (fc = 03)\n"
		"    ri - read input register(s) (fc = 04)\n"
		"    wc - write coil(s) (fc = 05|15)\n"
		"    wh - write holding register(s) (fc = 06|16)\n\n"
		"    <address> - 16-bit hex or dec value (0x0000..0xFFFF)\n"
		"    <count> - hex or dec value (1..2000 for rc and rd,\n" 
		"                                1..125 for rh and ri,\n" 
		"                                1..1968 for wc,\n" 
		"                                1..120 for wh,\n"
		"                                default: 1)\n\n"
		"    <values> - for wh comma separated list 16-bit or 32-bit of hex or dec values\n"
		"	        or 32-bit float values\n"
		"	        use prefixes: s - for signed, l - for long (32-bit) or sl - for signed long values\n"
		"	       for wc comma separated list of 8-bit hex or dec values (0x00..0xFF)\n"
		"	        max. length - 10\n\n"
		"  <connection> - (<ip>[:<port>])|(<serial_dev>:<baud>[,<params>])\n"
		"    <ip> - TCP ip address, default: 127.0.0.1\n"
		"    <port> - TCP port, default: 502\n"
		"    <serial_dev> - serial device path (/dev/tty.*)\n"
		"    <baud> - serial baudrate (300|600|1200|2400|4800|9600|19200|38400|57600|115200|230400)\n"
		"    <params> - serial parameters ([5678][OEN][12]), default: 8N1\n\n"
		"    <timeout> - response timeout in [ms] (default: 500ms)\n\n";

const char *action_map[] = {"rc", "rd", "rh", "ri", "wc", "wh"}; 

%%{
	machine options;
	access ctx->;

    action anything {
    	DEBUG("state: %d, char: %c\n", fcurs, *p);
    }

	action append {
		if (ctx->buflen < BUFLEN)
			ctx->buffer[ctx->buflen++] = fc;
	}

	action term {
		if (ctx->buflen < BUFLEN)
			ctx->buffer[ctx->buflen++] = 0;
	}

	action clear { ctx->buflen = 0; }

	action set_port { 
		ctx->port = strtol(ctx->buffer, NULL, 10);
		DEBUG("set_port: %d\n", ctx->port);
	}

	action set_ip {
		strlcpy(ctx->ip, ctx->buffer, 16);
		DEBUG("set_ip: %s\n", ctx->ip);
	}

	action append_check_len {
		if (ctx->buflen < BUFLEN)
			ctx->buffer[ctx->buflen++] = fc;
		if(ctx->buflen > 15)
		{
			ctx->ex_flag = LEN_EXCEPTION;
			fbreak;
		}
	}

	action set_device {
		strlcpy(ctx->device, ctx->buffer, 64);
		DEBUG("set_device: %s %d\n", ctx->device, ctx->buflen);
	}

	action set_baud { 
		ctx->baud = strtol(ctx->buffer, NULL, 10);
		DEBUG("set_baud: %d\n", ctx->baud);
	}

	action set_db {
		ctx->data_bit = fc - '0';
		DEBUG("set_db: %d\n", ctx->data_bit);
	}

	action set_parity {
		ctx->parity = fc;
		DEBUG("set_parity: %c\n", ctx->parity);
	}

	action set_sb {
		ctx->stop_bit = fc - '0';
		DEBUG("set_sb: %d\n", ctx->stop_bit);
	}

	action help_opt {
		options_help();
	}

	action version_opt { printf("version: " VERSION_STRING"\n"); }

	action debug_opt {
		ctx->debug = 1;
		DEBUG("debug enabled\n");
	}

	action inverse_opt {
		ctx->inverse = 1;
		DEBUG("inverse enabled\n");
	}

	action timeout_opt {
		int tmout;
		tmout = strtol(ctx->buffer, NULL, 10);
		ctx->timeout.tv_usec=1000*(tmout%1000);
		ctx->timeout.tv_sec=tmout/1000;
		DEBUG("timeout: %lds %ldus\n",ctx->timeout.tv_sec, ctx->timeout.tv_usec);
	}


	action set_action_t { 
		DEBUG("action type: \"%s\"\n", ctx->buffer); 
		switch(ctx->buffer[0])
		{
			case 'r':
				switch(ctx->buffer[1])
				{
					case 'c':
						ctx->action = _RC;
					break;

					case 'd':
						ctx->action = _RD;
					break;

					case 'h':
						ctx->action = _RH;
					break;

					case 'i':
						ctx->action = _RI;
					break;

					default:
						DBG_ASSERT(0,"Unhandled action char: %c",ctx->buffer[1]);
				}
			break;

			case 'w':
				ctx->count = 0;
				switch(ctx->buffer[1])
				{
					case 'c':
						ctx->action = _WC;
					break;

					case 'h':
						ctx->action = _WH;
					break;

					default:
						DBG_ASSERT(0,"Unhandled action char: %c",ctx->buffer[1]);
				}
			break;

			default:
				DBG_ASSERT(0,"Unhandled action char: %c",ctx->buffer[0]);
		}

		DEBUG("set_action_type: %s\n", ctx->buffer);
	}

	action set_address { 
		if((ctx->buffer[0] == '0') && (ctx->buffer[1] == 'x'))
			ctx->address = strtol(ctx->buffer, NULL, 16);
		else
			ctx->address = strtol(ctx->buffer, NULL, 10);

		DEBUG("set_address: %d\n", ctx->address); 
	}

	action set_count { 
		if((ctx->buffer[0] == '0') && (ctx->buffer[1] == 'x'))
			ctx->count = strtol(ctx->buffer, NULL, 16);
		else
			ctx->count = strtol(ctx->buffer, NULL, 10);

		DEBUG("set_count: %d\n", ctx->count); 
	}

	action count_values {
		ctx->count++;
		if(ctx->count >= 10)
		{
			ctx->ex_flag = LEN_EXCEPTION;
			fbreak;
		}
	}

	action add_value {
		int v;
		if((ctx->buffer[0] == '0') && (ctx->buffer[1] == 'x'))
			v = strtol(ctx->buffer, NULL, 16);
		else
			v = strtol(ctx->buffer, NULL, 10);

		if(v>MAX_UINT) {
			ctx->ex_flag = RANGE_EXCEPTION;
			fbreak;
		}

		switch(ctx->action)
		{
			case _WH:
				ctx->reg_values[ctx->index++] = v;
				break;

			case _WC:
				ctx->coil_values[ctx->index++] = v;
				break;

			default:
				DBG_ASSERT(0,"Unhandled action: %s", action_map[ctx->action]);

		}
		DEBUG("add_value: %d (count: %d index: %d)\n", v, ctx->count+1, ctx->index);
	}

	action add_svalue {
		int v;
		char *p = ctx->buffer;
		if(ctx->buffer[0] == '-')
			p++;

		if((p[0] == '0') && (p[1] == 'x'))
			v = strtol(ctx->buffer, NULL, 16);
		else
			v = strtol(ctx->buffer, NULL, 10);

		if((v > MAX_INT) || (v < MIN_INT))
		{
			ctx->ex_flag = RANGE_EXCEPTION;
			fbreak;
		} else {
			ctx->reg_values[ctx->index++] = v;
			DEBUG("add_svalue: %d (count: %d index: %d)\n", v, ctx->count+1, ctx->index);
		}		

	}

	action add_lvalue {
		unsigned long v;
		uint32_t lv;
		uint16_t lvl, lvh;

		if((ctx->buffer[0] == '0') && (ctx->buffer[1] == 'x'))
			v = strtoul(ctx->buffer, NULL, 16);
		else
			v = strtoul(ctx->buffer, NULL, 10);

		if(v>MAX_L_UINT) {
			ctx->ex_flag = RANGE_EXCEPTION;
			fbreak;
		}
		
		lv = *(uint32_t*)&v;
		if(ctx->inverse) {
			lvh = lv&0xFFFF;
			lvl = lv>>16;
		} else {
			lvl = lv&0xFFFF;
			lvh = lv>>16;
		}

		ctx->reg_values[ctx->index++] = lvl;
		ctx->reg_values[ctx->index++] = lvh;
		DEBUG("add_lvalue: %u (hex: %04x|%04x count: %d index: %d)\n", lv, lvh, lvl, ctx->count+1, ctx->index);
	}

	action add_slvalue {
		long int v;
		uint32_t lv;
		uint16_t lvl, lvh;

		char *p = ctx->buffer;
		if(ctx->buffer[0] == '-')
			p++;

		if((p[0] == '0') && (p[1] == 'x'))
			v = strtol(ctx->buffer, NULL, 16);
		else
			v = strtol(ctx->buffer, NULL, 10);

		if((v > MAX_L_INT) || (v < MIN_L_INT))
		{
			ctx->ex_flag = RANGE_EXCEPTION;
			fbreak;
		}

		lv = *(uint32_t*)&v;
		if(ctx->inverse) {
			lvh = lv&0xFFFF;
			lvl = lv>>16;
		} else {
			lvl = lv&0xFFFF;
			lvh = lv>>16;
		}

		ctx->reg_values[ctx->index++] = lvl;
		ctx->reg_values[ctx->index++] = lvh;
		DEBUG("add_slvalue: %ld (hex: %04x|%04x count: %d index: %d)\n", v, lvh, lvl, ctx->count+1, ctx->index);		

	}

	action add_float_value {
		float v;
		uint32_t lv;
		uint16_t lvl, lvh;

		v = atof(ctx->buffer);
		lv = *(uint32_t*)&v;
		if(ctx->inverse) {
			lvh = lv&0xFFFF;
			lvl = lv>>16;
		} else {
			lvl = lv&0xFFFF;
			lvh = lv>>16;
		}

		ctx->reg_values[ctx->index++] = lvl;
		ctx->reg_values[ctx->index++] = lvh;
		DEBUG("add_float_value: %f (hex: %x|%x count: %d index: %d)\n", v, lvh, lvl, ctx->count+1, ctx->index);
	}

	action tcp {
		ctx->connection_type = _TCP;
	}

	action serial {
		ctx->connection_type = _RTU;
	}

	alphanum = alpha | digit;
	dec_octet = digit | ( 0x31..0x39 digit ) | ( "1" digit{2} ) | ( "2" 0x30..0x34 digit ) | ( "25" 0x30..0x35 );

	dec_16bit = (( digit{1,4} |
		 "1".."5" digit{4} |
		 "6" "0".."4" digit{3} |
		 "6" "5" "0".."4" digit{2} |
		 "6" "5" "5" "0".."2" digit |
		 "6" "5" "5" "3" "0".."5"
	) - ( "00" | "000" | "0000" ));

	dec_8bit = (("2" "5" "0".."5" | "2" "0".."4" digit | "1" digit{2} | digit digit | digit) -
			("00" | "000"));

	hex_16bit = ("0x" [0-9a-fA-F]{1,4});
	hex_32bit = ("0x" [0-9a-fA-F]{1,8});
	hex_8bit = ("0x"[0-9a-fA-F]{1,2}) >clear $append %term;

	IPv4address = (dec_octet "." dec_octet "." dec_octet "." dec_octet)  >clear $append %term;

	tcp = IPv4address %set_ip (':' (dec_16bit - "0") %set_port)?;

	serial_baud = ("300" | "600" | "1200" | 
		      "2400" | "4800" | "9600" |
		      "19200" | "38400" | "57600" |
		      "115200" | "230400") >clear $append %term;

	serial_dev = ("/dev/tty" alphanum*) >clear $append_check_len %term;
	serial_params = [5..8] >set_db [OENoen] >set_parity [12] >set_sb;
	serial = (serial_dev %set_device ":" serial_baud %set_baud ("," serial_params)?);

	action_type_read = ("rc"|"rd"|"rh"|"ri") >clear $append %term;
	action_type_wc = ("wc") >clear $append %term;
	action_type_wh = ("wh") >clear $append %term;
	_16bit = (hex_16bit | dec_16bit) >clear $append %term;
	_8bit = (hex_8bit | dec_8bit);
	exponent = ([eE] ("+"|"-")? [0-9]+)?;
	_32bitfloat = ("-"? [0-9]+ "." [0-9]* exponent?) >clear $append %term;

	
	dec = [0-9]{1,10};
	val = (hex_16bit | dec) >clear $append %term;
	sval = ("-"? (hex_16bit | dec)) >clear $append %term;
	lval = (hex_32bit | dec) >clear $append %term;
	slval = ("-"? (hex_32bit | dec)) >clear $append %term;
	wh_dec_value = (val %add_value | 
			("s" sval %add_svalue) | 
			("l" lval %add_lvalue) | 
			("sl" slval %add_slvalue));

	wh_value = (wh_dec_value | _32bitfloat %add_float_value);

	wh_list = wh_value ("," %count_values wh_value)*;
	_8bit_list = _8bit %add_value ("," %count_values _8bit %add_value)*;
	
	action_read = action_type_read %set_action_t ":" _16bit %set_address (":" _16bit %set_count)?;
	action_write_wh = action_type_wh %set_action_t ":" _16bit %set_address ":" wh_list;
	action_write_wc = action_type_wc %set_action_t ":" _16bit %set_address ":" _8bit_list;

	_action = (action_read|action_write_wh|action_write_wc);

	#different arguments.
	help_opt = ( "-h" | "-H" | "-?" | "--help" ) 0 @help_opt;
	version_opt = ( "-v" | "--version" ) 0 @version_opt;
	debug_opt = ("-d" | "--debug") 0 @debug_opt;
	inverse_opt = ("-i" | "--inverse") 0 @inverse_opt;
	timeout_opt = (("-t"  | "--timeout") 0? ([0-9]{1,5}) >clear $append %term) 0 @timeout_opt;
	connection_opt = "-c" 0? (tcp %tcp | serial %serial) 0;
	action_opt = _action 0;

	main := (help_opt | version_opt )* | ((timeout_opt | debug_opt | inverse_opt | connection_opt)* action_opt); #$anything;

}%%

%% write data;

void options_init(options_t *ctx)
{
	ctx->action = _UNDEF;
	ctx->buflen = 0;

	ctx->ex_flag = 0;

	ctx->debug = 0;
	ctx->inverse = 0;

	ctx->timeout.tv_sec = 0;
	ctx->timeout.tv_usec = DEFAULT_RESP_TIMEOUT;

	ctx->connection_type = _TCP;
	ctx->port = 502;
	strlcpy(ctx->ip, "127.0.0.1", 16);

	ctx->data_bit = 8;
	ctx->parity = 'N';
	ctx->stop_bit = 1;
	
	ctx->count = 1;
	ctx->index = 0;

	%% write init;
}

void options_execute(options_t *ctx, const char *data, int len)
{
	const char *p = data;
	const char *pe = data + len;

	%% write exec;

	ctx->p = p;
}

int options_finish(options_t *ctx)
{
	if ( ctx->cs == options_error || ctx->ex_flag)
		return -1;
	if ( ctx->cs >= options_first_final )
		return 1;
	return 0;
}

void options_dump(options_t *ctx)
{
	printf("Options:\n");
	printf("Action definition: type=%s address=%d count=%d\n",
			action_map[ctx->action], ctx->address, ctx->count);
	switch(ctx->connection_type)
	{
	case _TCP:
		printf("Connection: type=TCP ip=%s port=%d\n", ctx->ip, ctx->port);
		break;

	case _RTU:
		printf("Connection: type=RTU device=%s baudrate=%d params=%d%c%d\n",
				ctx->device, ctx->baud, ctx->data_bit, ctx->parity, ctx->stop_bit);
		break;

	default:
		DBG_ASSERT(0,"Unhandled connection enum constant!");
	}
}

void options_help()
{
	printf("Usage: %s [-h -H -? --help -v --version] [-d --debug] [-i --inverse] "
			"[-t --timeout <timeout>] [-c <connection>] <action>\n%s",
			PROGRAM_NAME, usage);
}

void options_err_disp(options_t *ctx, const char *cmd)
{
	fprintf( stderr, "options: error processing argument: %s\n", cmd);
	fprintf( stderr, "                                    ");
	fprintf( stderr, "%*s" "^\n", ctx->ex_flag ? ctx->p-cmd-2 : ctx->p-cmd, " ");
	
	switch(ctx->ex_flag)
	{
	case LEN_EXCEPTION:
		fprintf( stderr, "options: string or list too long\n");
		break;

	case RANGE_EXCEPTION:
		fprintf( stderr, "options: value out of range\n");
		break;

	case 0:
		fprintf( stderr, "options: unable to parse option\n");
		break;
	
	default:
		DBG_ASSERT(0,"Unhandled exception enum constant!");
	}	
}
