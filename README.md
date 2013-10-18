moddiag - simple commandline Modbus client
==========================================

Introduction
------------

Moddiag is a simple commandline interface to the libmodbus library. It uses the Ragel state machine compiler for commandline options parsing. It was created mainly to learn Ragel syntax and libmodbus library API. It is work in progress and cannot be considered stable or error free. Any comments, patches and bug reports are welcome.

Building
--------
Moddiag has following dependencies:

* [libmosbus library](http://libmodbus.org/)
* [Ragel State Machine Compiler](http://www.complang.org/ragel/) for commandline options parsing
* cmake build system

It is recommended to install ragel in the default location so the ragel command is available. It is better to build libmodbus library form source using the --enable-static configure option and install it in custom location using --prefix option. To configure and build moddiag:

1. Go to the moddiag main directory and execute:

        mkdir build; cd build
        
        cmake -DCMAKE_PREFIX_PATH=/path/to/libmodbus/install/dir ..
    or
    
        cmake -DCMAKE_PREFIX_PATH=/path/to/libmodbus/install/dir  -DSTATIC_LINK=On ..
        
    for statically linking the libmodbus library
    
2. Compile the application using:

        make

It is possible to uncomment the `DEBUG_PRINT_ENABLED` define in the moddiag.h file to enable detailed debug output of the commandline options parsing process.
 
Usage
-----

    Usage: moddiag [-h -H -? --help -v --version] [-d --debug] [-i --inverse] [-t --timeout <timeout>] [-c <connection>] <action>
                Where:
                <action> - ((rc|rd|rh|ri):<address>[:<count>])|((wc|wh):<address>:<values>)
                    rc - read coil(s) (fc = 0x01)
                    rd - read discrete input(s) (fc = 02)
                    rh - read holding register(s) (fc = 03)
                    ri - read input register(s) (fc = 04)
                    wc - write coil(s) (fc = 05|15)
                    wh - write holding register(s) (fc = 06|16)

                    <address> - 16-bit hex or dec value (0x0000..0xFFFF)
                    <count> - hex or dec value (1..2000 for rc and rd,
                                                1..125 for rh and ri,
                                                1..1968 for wc,
                                                1..120 for wh,
                                                default: 1)

                    <values> - for wh comma separated list 16-bit or 32-bit of hex or dec values
                            or 32-bit float values
                            use prefixes: s - for signed, l - for long (32-bit) or sl - for signed long values
                        for wc comma separated list of 8-bit hex or dec values (0x00..0xFF)
                            max. length - 10

                <connection> - (<ip>[:<port>])|(<serial_dev>:<baud>[,<params>])
                    <ip> - TCP ip address, default: 127.0.0.1
                    <port> - TCP port, default: 502
                    <serial_dev> - serial device path (/dev/tty.*)
                    <baud> - serial baudrate (300|600|1200|2400|4800|9600|19200|38400|57600|115200|230400)
                    <params> - serial parameters ([5678][OEN][12]), default: 8N1

                    <timeout> - response timeout in [ms] (default: 500ms)
                    

                    
TODO
----

* remove the `<values>` list length limit (currently: 10) 
* add various unit tests

Contact
-------
If you have questions, contact Maiusz Ryndzionek at:

<mryndzionek@gmail.com>