mp.sh
=====

This is a set of `sh` functions that implement (slow) arbitrary
precision arithmetic.  At the moment, only operations on the natural
numbers are supported.

I started it in in response to
[a challenge by rethinkdb.com](http://news.ycombinator.com/item?id=4072637)
and continued because it was fun :-) However, do not rely on these
functions for any multiprecision arithmetic in the shell -- use
[bc](http://linux.die.net/man/1/bc) instead!

How to use it
-------------

Don't.  Didn't I tell you to use [bc](http://linux.die.net/man/1/bc) instead?

Anyway, the files `mp.bash` (for bash) and `mp.sh` (for a generic
POSIX shell) define arithmetic functions, that operate on arbitrary
precision natural numbers, and output the result:

* `mp_add` output the sum of its arguments:

        mp_add 3 5
        8

* `mp_sub` subtract the second argument from the first:

        mp_sub 10 2
        8

* `mp_mul` output the product of its arguments:

        mp_mul 2 3 4
        24

* `mp_div` output the quotient obtained by integer division of the
  first argument by the second:
  
        mp_div 50 2
        25

The only exception to this pattern is function `mp_lt` which does not
output anything, but exits with code 0 if the first argument is
nunerically less than the second, and code 1 viceversa.

Take a look at file [test.sh](test.sh) to see how these functions are
used; if you run the file, you should get a unit test output like the
following:

    $ ./test.sh
    TEST: less-than test cases ...
    expecting 0, got 0 [*OK*]
    expecting 1, got 1 [*OK*]
    expecting 0, got 0 [*OK*]
    expecting 1, got 1 [*OK*]
    ...
    TEST: sum test cases ...
    expecting 2, got 2 [*OK*]
    expecting 6, got 6 [*OK*]
    expecting 60, got 60 [*OK*]
    expecting 1111, got 1111 [*OK*]
    ...
    TEST: digits of e test cases ...
    expecting 2.7, got 2.7 [*OK*]
    expecting 2.71, got 2.71 [*OK*]
    expecting 2.7182, got 2.7182 [*OK*]
    ...

