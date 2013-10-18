#!/bin/sh

ACTIONLIST="action_read action_write_wh action_write_wc tcp serial version_opt \
help_opt debug_opt inverse_opt timeout_opt"

command -v ragel >/dev/null 2>&1 || 
	{ echo >&2 "The Ragel State Machine Compiler is required.  Aborting."; exit 1; }
command -v dot >/dev/null 2>&1 || 
	{ echo >&2 "The dot utility form Graphviz package is required.  Aborting."; exit 1; }

mkdir -p graphs
for action in $ACTIONLIST;do
	echo "Generating graph for action: $action"
	ragel -Vp -M $action -o graphs/$action.dot options.rl
	dot -Tps -o graphs/$action.ps graphs/$action.dot
	dot -Tpng -o graphs/$action.png graphs/$action.dot
done
