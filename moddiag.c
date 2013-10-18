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
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>

#include "moddiag.h"
#include "options.h"

int main( int argc, char **argv )
{
	int a, rc;
	int ec = 0;
	options_t options;
	modbus_t *ctx;

	uint8_t *tab_bit;
	uint16_t *tab_reg;

	if(argc > 1)
	{
		options_init(&options);
		for (a = 1; a < argc; a++)
		{
			options_execute(&options, argv[a], strlen(argv[a])+1);
			rc = options_finish(&options);
			DEBUG("argument: '%s' end state: %d\n",argv[a], rc);

			if (rc == -1)
			{
				options_err_disp(&options,argv[a]);
				ec = 1;
				goto exit;
			}
		}

		if(rc == 0)
		{
			fprintf(stderr, "Missing action argument\n");
			ec = 1;
			goto exit;
		}

		if(options.action == _UNDEF)
			goto exit;

		// Options are valid 
		options_dump(&options);
	
		ctx = modbus_init_con(&options);
		modbus_set_debug(ctx, options.debug);
		modbus_set_response_timeout(ctx, &options.timeout);

		if (modbus_connect(ctx) == -1) {
			fprintf(stderr, "Connection failed: %s\n",
				modbus_strerror(errno));
			ec = 1;
			goto destroy;
		}

		switch(options.action)
		{
			case _RC:
			case _RD:
				tab_bit = (uint8_t *) malloc(options.count * sizeof(uint8_t));
				DBG_ASSERT(tab_bit != NULL, "Unable to allocate tab_bit!");
				memset(tab_bit, 0, options.count * sizeof(uint8_t));
				
				switch(options.action)
				{
					case _RC:
						rc = modbus_read_bits(ctx, options.address, 
								options.count, tab_bit);
					break;

					case _RD:
						rc = modbus_read_input_bits(ctx, options.address, 
								options.count, tab_bit);

					break;
				}
				if (rc == -1) {
					fprintf(stderr, "%s\n", modbus_strerror(errno));
					ec = 1;
				} else {
					display_8bit(&options, tab_bit);
				}
				free(tab_bit);
			break;

			case _RH:
			case _RI:
				tab_reg = (uint16_t *) malloc(options.count * sizeof(uint16_t));
				DBG_ASSERT(tab_reg != NULL, "Unable to allocate tab_reg!");
				
				switch(options.action)
				{
					case _RH:
						rc = modbus_read_registers(ctx, options.address, 
								options.count, tab_reg);
					break;

					case _RI:
						rc = modbus_read_input_registers(ctx, options.address, 
								options.count, tab_reg);

					break;
				}
				if (rc == -1) {
					fprintf(stderr, "%s\n", modbus_strerror(errno));
					ec = 1;
				} else {
					display_16bit(&options, tab_reg);
				}
				free(tab_reg);
			break;

			case _WC:
				if(options.count == 1)
					rc =  modbus_write_bit(ctx, options.address, 
							options.coil_values[0]);
				else {
					rc = modbus_write_bits(ctx, options.address,
							options.count, options.coil_values);
				}

				if (rc == -1) {
					fprintf(stderr, "%s\n", modbus_strerror(errno));
					ec = 1;
				} else {
					printf("Success\n");
				}
			break;

			case _WH:
				if(options.count == 1)
					rc =  modbus_write_register(ctx, options.address, 
							options.reg_values[0]);
				else {
					rc = modbus_write_registers(ctx, options.address,
							options.count, options.reg_values);
				}

				if (rc == -1) {
					fprintf(stderr, "%s\n", modbus_strerror(errno));
					ec = 1;
				} else {
					printf("Success\n");
				}

			break;

			default:
				DBG_ASSERT(0,"Unhandled action enum constant!");
		}



	} else {
		options_help();
		ec = 1;
		goto exit;
	}

close:
	modbus_close(ctx);
destroy:
	modbus_free(ctx);
exit:
	return ec;
}

modbus_t* modbus_init_con(options_t *opt)
{
	modbus_t *ctx;

	switch(opt->connection_type)
	{
		case _TCP:
			ctx = modbus_new_tcp(opt->ip, opt->port);
			DBG_ASSERT(ctx != NULL,"Unable to allocate libmodbus TCP context");
			modbus_set_slave(ctx, 1);
		break;

		case _RTU:
			ctx = modbus_new_rtu(opt->device, opt->baud, opt->parity, opt->data_bit, opt->stop_bit); 
			DBG_ASSERT(ctx != NULL,"Unable to allocate libmodbus RTU context");
		break;

		default:
			DBG_ASSERT(0,"Unhandled connection type %d", opt->connection_type);
	}

	return ctx;

}

void display_16bit(options_t *opt, uint16_t *tab)
{
	int i;
	for(i=0; i<opt->count; i++)
		printf("Addr: 0x%04x Value: %04x\n",opt->address+i, tab[i]);
}

void display_8bit(options_t *opt, uint8_t *tab)
{
	int i;
	for(i=0; i<opt->count; i++)
		printf("Addr: 0x%04x Value: %04x\n",opt->address+i, tab[i]);
}
