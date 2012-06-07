#! /bin/bash
#
# Compute Euler's number up to a precision of N decimal digits,
# using mp.sh/mp.bash
#

## usage

PROG="$(basename $0)"

usage () {
cat <<EOF
Usage: $PROG [options] N

Compute Euler's number up to a precision of N decimal digits.
(Warning: N>8 will consume significant time and memory...)

Options:

  --help, -h  Print this help text.

EOF
}


## helper functions
die () {
  rc="$1"
  shift
  (echo -n "$PROG: ERROR: ";
      if [ $# -gt 0 ]; then echo "$@"; else cat; fi) 1>&2
  exit $rc
}

warn () {
  (echo -n "$PROG: WARNING: ";
      if [ $# -gt 0 ]; then echo "$@"; else cat; fi) 1>&2
}

## parse command-line

short_opts='hT'
long_opts='help,test'

if [ "x$(getopt -T)" != 'x--' ]; then
    # GNU getopt
    args=$(getopt --name "$PROG" --shell sh -l "$long_opts" -o "$short_opts" -- "$@")
    if [ $? -ne 0 ]; then
        die 1 "Type '$PROG --help' to get usage information."
    fi
    # use 'eval' to remove getopt quoting
    eval set -- $args
else
    # old-style getopt, use compatibility syntax
    args=$(getopt "$short_opts" "$@")
    if [ $? -ne 0 ]; then
        die 1 "Type '$PROG --help' to get usage information."
    fi
    set -- $args
fi

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --) shift; break ;;
    esac
    shift
done


## main

# load appropriate library of functions (mp.bash is faster)
if [ "_$BASH" = '_' ]; then
    # not bash, assume POSIX sh
    . ./mp.sh
else
    # we're running bash
    . mp.bash
fi

# compute E
digits_of_e "${1}"
