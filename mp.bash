#! /bin/bash
#
# A library of sh functions for doing multiprecision arithmetic.
# This file contains the definitions taking advantage of the
# bash shell builtins, which make it faster than the generic
# POSIX shell version.
#


## sanity checks

have_command () {
  type "$1" >/dev/null 2>/dev/null
}

require_command () {
  if ! have_command "$1"; then
    die 1 "Could not find required command '$1' in system PATH. Aborting."
  fi
}

require_command rev
require_command sed


## library functions

# _do_many BINOP ARG [ARG ...]
#
# execute associative BINOP on list of arguments
#
_do_many () {
    if [ $# -le 2 ]; then
        echo "${2}"
    else
        local binop="${1}"
        local first="${2}"
        local second="${3}"
        shift 3
        _do_many ${binop} "$(${binop} "${first}" "${second}")" "$@"
    fi

}


# remove leading zeroes from a number
normalize () {
    sed -r -e 's/^0+//'
}

# remove leading 0s from an RTL number, i.e., remove trailing zeroes
_normalize () {
    sed -r -e 's/0+$//'
}


# mp_lt A B
#
# exit successfully if A is numerically less than B
#
mp_lt () {
    # remove leading zeroes
    local a=$( echo ${1} | normalize)
    local b=$( echo ${2} | normalize)
    local len_a=${#a}
    local len_b=${#b}
    # shortcut: if A has less digits than B, then it's less-than
    if [ "$len_a" -lt "${len_b}" ]; then
        return 0
    # if A and B have the same number of digits, use lexical comparison
    elif [ "${len_a}" -eq "${len_b}" ]; then
        if [ "${len_a}" -eq 0 ]; then
            # special case for _mp_div2
            return 0
        else
            local a1=${1:0:1}
            local b1=${2:0:1}
            if [ "${a1}" -lt "${b1}" ]; then
                return 0
            elif [ "${a1}" -eq "${b1}" ]; then
            # recurse
                local a2=${1:1}
                local b2=${2:1}
                mp_lt "${a2}" "${b2}"
            else
            # b1 > a1, hence B > A
                return 1
            fi
        fi
    else
        return 1
    fi
}

# same as `mp_lt`, but using the RTL representation
_mp_lt () {
    mp_lt "$(echo "${1}" | rev)" "$(echo "${2}" | rev)"
}


mp_add () {
    _do_many mp_add2 "$@"
}

mp_add2 () {
    _mp_add2 "$(echo "${1}" | rev)" "$(echo "${2}" | rev)" | rev
}

# add ${1} and ${2}, print result to STDOUT
_mp_add2 () {
    local pfx="${4}"
    local carry="${3}"
    if [ -z "${1}" ] || [ -z "${2}" ]; then
        if [ -z "${carry}" ]; then
            echo "${pfx}${1}${2}" | _normalize
        else
            _mp_add2 "${1}${2}" "${carry}" '' "${pfx}"
        fi
    else
        local a1=${1:0:1}
        local b1=${2:0:1}
        local a2=${1:1}
        local b2=${2:1}
        if [ -n "${3}" ]; then
            carry="${3}"
        else
            carry='0'
        fi
        local tot=$(echo $(( ${a1} + ${b1} + ${carry} )) | rev )
        local d=${tot:0:1}
        carry=${tot:1}
        _mp_add2 "${a2}" "${b2}" "${carry}" "${pfx}${d}"
    fi
}


mp_sub () {
    _do_many mp_sub2 "$@"
}

mp_sub2 () {
    _mp_sub2 "$(echo "${1}" | rev)" "$(echo "${2}" | rev)" | rev
}

_mp_sub2 () {
    local pfx="${4}"
    local carry="${3}"
    a=$(echo "${1}" | _normalize)
    b=$(echo "${2}" | _normalize)
    if [ "${a}" = "${b}" ] && [ -z "${carry}" ]; then
        # shortcut
        if [ -z "${pfx}" ]; then
            echo '0'
        else
            echo "${pfx}" | _normalize
        fi
        return 0
    elif [ -z "${a}" ]; then
        if [ -z "${b}" ]; then
            # end of recursion
            echo "${pfx}" | _normalize
            return 0
        else
            echo 1>&2 "ERROR: negative numbers not supported."
            return 1
        fi
    elif [ -z "${b}" ]; then
        #
        if [ -z "${carry}" ]; then
            echo "${pfx}${a}"
        else
            _mp_sub2 "${a}" "${carry}" '' "${pfx}"
        fi
    else
        local a1=${1:0:1}
        local b1=${2:0:1}
        local a2=${1:1}
        local b2=${2:1}
        if [ -z "${carry}" ]; then
            carry=0
        fi
        local d=$(( ${a1} - ${b1} - ${carry} ))
        case "$d" in
            -*) # reduce mod 10
                d=$(( ${d} + 10 ))
                carry=1
                ;;
            *)
                carry=0
                ;;
        esac
        _mp_sub2 "${a2}" "${b2}" "${carry}" "${pfx}${d}"
    fi
}


mp_mul () {
    _do_many mp_mul2 "$@"
}

mp_mul2 () {
    _mp_mul2 "$(echo "${1}" | rev)" "$(echo "${2}" | rev)" | rev
}

# decompose a = a1 + 10*a2 where 0<=a1<=9 and use distributive law +
# the fact that multiplication by 10 is just a shift in the digits
_mp_mul2 () {
    if [ -z "${1}" ] || [ -z "${2}" ]; then
        echo ''
    else
        local a1=${1:0:1}
        local b1=${2:0:1}
        local a2=${1:1}
        local b2=${2:1}
        # a*b = (a1 + 10*a2)*(b1 + 10*b2) = a1*b1 + 10*(a2*b1 + a1*b2) + 100*a2*b2
        #                                     t1         t2'     t2''         t3
        local t=$(echo $(( ${a1} * ${b1} )) | rev )
        local t2_1=$(_mp_mul2 "${a1}" "${b2}")
        local t2_2=$(_mp_mul2 "${a2}" "${b1}")
        local t2=$(_mp_add2 "${t2_1}" "${t2_2}")
        if [ -n "${t2}" ]; then
            t=$(_mp_add2 "${t}" "0${t2}")
        fi
        local t3=$(_mp_mul2 "${a2}" "${b2}")
        if [ -n "${t3}" ]; then
            t=$(_mp_add2 "${t}" "00${t3}")
        fi
        echo "${t}"
    fi
}


mp_div () {
    _do_many mp_div2 "$@"
}

mp_div2 () {
    _mp_div2 "$(echo "${1}" | rev)" "$(echo "${2}" | rev)" | rev
}

# let q = a // b (where '//' denotes integer division), and write
# q = q1 + 10*q2; now we have:
#
#   * q2 = (a // b*10) = (a // 10) // b = (a2 // b): multiplication and
#     division by 10 can be implemented as shifts;
#   * q1 = (a - q2*10) // b
#
_mp_div2 () {
    if [ -z "${1}" ] || [ -z "${2}" ]; then
            echo ''
            return 0
    else
        local a="${1}"
        local b="${2}"
        if _mp_lt "${a}" "${b}"; then
            echo '0'
        else
            # compute q2 by recursion
            a2=${a:1}
            local q2=$(_mp_div2 "${a2}" "${b}")
            # iteratively compute q1
            local q1=0
            if _mp_lt "0${q2}" "${a}"; then
                local r=$(_mp_sub2 "${a}" $(_mp_mul2 "0${q2}" "${b}"))
                while _mp_lt "${b}" "${r}"; do
                    q1=$(( 1 + ${q1} ))
                    r=$(_mp_sub2 "${r}" "${b}")
                done
            fi
            echo "$(_mp_add2 "${q1}" "0${q2}")"
        fi
    fi
}


# _many N STR
#
# output concatentation of N copies of STR
_many () {
    if [ "${1}" -gt 0 ]; then
        echo "${2}$(_many $(( ${1} - 1)) "${2}" )"
    else
        echo ''
    fi
}


# digits_of_e N
#
# output Euler's number with a precision of N decimal digits
# E=2.7182818284590452353602874713527...
#
digits_of_e () {
    N="${1}"

    # compute E by summing the series \sum (1/k!)
    # multiply whole series by 10^(N+2) so we can use just int arithmetic;
    # the extra 2 digits are for better accuracy
    e="2$(_many $N 0)00"
    numerator="1$(_many $N 0)00"
    denominator=1
    k=2
    term="${numerator}"
    while mp_lt 100 "${term}"; do
        denominator=$(mp_mul "${denominator}" "${k}")
        term=$(mp_div "${numerator}" "${denominator}")
        e=$(mp_add "${e}" "${term}")
        k=$(( ${k} + 1 ))
    done
    echo "2.${e:1:$N}"
}
