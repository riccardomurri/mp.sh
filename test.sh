#! /bin/bash
#
# Unit tests for the functions in mp.sh/mp.bash
#


# load appropriate library of functions (mp.bash is faster)
if [ "_$BASH" = '_' ]; then
    # not bash, assume POSIX sh
    . ./mp.sh
else
    # we're running bash
    . mp.bash
fi


## helpers for uni tests

# _test EXPECTED FN ARG [ARG ...]
#
# run FN with ARGs and compare its output with string EXPECTED
_test () {
    local expect="${1}"
    shift
    echo -n "expecting ${expect}, got "
    local output=$("$@" | tr -d '\n')
    echo -n "${output}"
    case "${output}" in
        "${expect}") echo " [*OK*]"; return 0 ;;
        *)           echo " [FAIL]"; return 1 ;;
    esac
}

# like `_test`, except the EXPECTED value is compared with the exitcode,
# converted to a boolean value (exit code = 0 -> TRUE, exit code !=0 -> FALSE)
_test_bool () {
    local expect="${1}"
    shift
    echo -n "expecting ${expect}, got "
    "$@"
    local output="$(_rc_to_bool $?)"
    echo -n "${output}"
    case "${output}" in
        "${expect}") echo " [*OK*]"; return 0 ;;
        *)           echo " [FAIL]"; return 1 ;;
    esac
}

_rc_to_bool () {
    if [ "${1}" -eq 0 ]; then
        echo 1
    else
        echo 0
    fi
}

# _randomize N TESTFN OP MPOP
#
# create N pairs of random numbers and compare the result of executing
# MPOP with the (assumedly correct) result of $(expr OP); use TESTFN
# for comparing results.
#
_randomize () {
    local n="${1}"
    local test_fn="${2}"
    local op="${3}"
    local mp_op="${4}"
    for _ in $(seq 1 "${n}"); do
        local n1="${RANDOM}${RANDOM}"
        local n2="${RANDOM}${RANDOM}"
        if [ "${n1}" -lt "${n2}" ]; then
            local tmp="${n1}"
            n1="${n2}"
            n2="${tmp}"
        fi
        local result=$(echo "${n1}" "${op}" "${n2}" | bc)
        #echo "DEBUG: ${n1} ${op} ${n2} = ${result}"
        $test_fn "${result}" "${mp_op}" "${n1}" "${n2}"
    done
}



test_mp_lt () {
    echo "TEST: less-than test cases ..."
    _test_bool 0 mp_lt 7 3
    _test_bool 1 mp_lt 3 7
    _test_bool 0 mp_lt 123 45
    _test_bool 1 mp_lt 45 123
    _randomize 3 _test_bool '<' mp_lt
}


test_mp_add () {
    echo "TEST: sum test cases ..."
    _test 2                 mp_add 2 00
    _test 6                 mp_add 1 2 3
    _test 60                mp_add 10 20 30
    _test 1111              mp_add 1000 100 10 1
    _test 10000000000001001 mp_add 10000000000000000 1000 1
    _randomize 3 _test '+' mp_add
}


test_mp_sub () {
    echo "TEST: sub test cases ..."
    _test 0          mp_sub 1 1
    _test 1          mp_sub 3 2
    _test 4          mp_sub 10 6
    _test 4          mp_sub 4 00
    _test 9999       mp_sub 10000 1
    _test 1632798756 mp_sub 1714215458 81416702
    _randomize 3 _test '-' mp_sub
}


test_mp_mul () {
    echo "TEST: mul test cases ..."
    _test 6                    mp_mul 1 2 3
    _test 125                  mp_mul 5 25
    _test 1000000              mp_mul 1000 100 10 1
    _test 10000000000000000000 mp_mul 10000000000000000 1000 1
    _test 245726072382356090   mp_mul 2055231367 119561270
    _randomize 3 _test '*' mp_mul
}


test_mp_div () {
    echo "TEST: div test cases ..."
    _test 2  mp_div 4 2
    _test 25 mp_div 50 2
    _test 5  mp_div 50 10
    _randomize 3 _test '/' mp_div
}


test_digits_of_e () {
    echo "TEST: digits of e test cases ..."
    _test '2.7'                digits_of_e 1
    _test '2.71'               digits_of_e 2
    _test '2.7182'             digits_of_e 4
    _test '2.71828182'         digits_of_e 8
    _test '2.7182818284590452' digits_of_e 16
}


# run test suite
test_mp_lt
test_mp_add
test_mp_sub
test_mp_mul
test_digits_of_e
