/*****************************************************************************
*
*                      Higgs JavaScript Virtual Machine
*
*  This file is part of the Higgs project. The project is distributed at:
*  https://github.com/maximecb/Higgs
*
*  Copyright (c) 2012, Maxime Chevalier-Boisvert. All rights reserved.
*
*  This software is licensed under the following license (Modified BSD
*  License):
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions are
*  met:
*   1. Redistributions of source code must retain the above copyright
*      notice, this list of conditions and the following disclaimer.
*   2. Redistributions in binary form must reproduce the above copyright
*      notice, this list of conditions and the following disclaimer in the
*      documentation and/or other materials provided with the distribution.
*   3. The name of the author may not be used to endorse or promote
*      products derived from this software without specific prior written
*      permission.
*
*  THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
*  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
*  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN
*  NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
*  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
*  NOT LIMITED TO PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
*  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
*  THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*****************************************************************************/

module interp.tests;

import std.stdio;
import std.string;
import std.math;
import parser.parser;
import ir.ast;
import interp.interp;
import repl;

void assertInt(Interp interp, string input, long intVal)
{
    assert (
        interp !is null,
        "interp object is null"
    );

    auto ret = interp.evalString(input);

    assert (
        ret.type == Type.INT,
        "non-integer value: " ~ valToString(ret)
    );

    assert (
        ret.word.intVal == intVal,
        format(
            "Test failed:\n" ~
            "%s" ~ "\n" ~
            "incorrect integer value: %s, expected: %s",
            input,
            ret.word.intVal, 
            intVal
        )
    );
}

void assertFloat(string input, double floatVal, double eps = 1E-4)
{
    auto ret = (new Interp()).evalString(input);

    assert (
        ret.type == Type.INT ||
        ret.type == Type.FLOAT,
        "non-numeric value: " ~ valToString(ret)
    );

    auto fRet = (ret.type == Type.FLOAT)? ret.word.floatVal:ret.word.intVal;

    assert (
        abs(fRet - floatVal) <= eps,
        format(
            "Test failed:\n" ~
            "%s" ~ "\n" ~
            "incorrect float value: %s, expected: %s",
            input,
            fRet, 
            floatVal
        )
    );
}

void assertBool(Interp interp, string input, bool boolVal)
{
    auto ret = interp.evalString(input);

    assert (
        ret.type == Type.CONST,
        "non-const value: " ~ valToString(ret)
    );

    assert (
        ret.word == (boolVal? TRUE:FALSE),
        format(
            "Test failed:\n" ~
            "%s" ~ "\n" ~
            "incorrect boolan value: %s, expected: %s",
            input,
            valToString(ret), 
            boolVal
        )
    );
}

void assertStr(string input, string strVal)
{
    auto ret = (new Interp()).evalString(input);

    assert (
        valIsString(ret.word, ret.type),
        "non-string value: " ~ valToString(ret)
    );

    auto outStr = valToString(ret);

    assert (
        outStr == strVal,
        format(
            "Test failed:\n" ~
            input ~ "\n" ~
            "incorrect string value: %s, expected: %s",
            outStr, 
            strVal
        )
    );
}

void assertInt(string input, long intVal)
{
    assertInt(new Interp(), input, intVal);
}

void assertBool(string input, bool boolVal)
{
    assertBool(new Interp(), input, boolVal);
}

unittest
{
    Word w0 = Word.intv(0);
    Word w1 = Word.intv(1);
    assert (w0.intVal != w1.intVal);
}

unittest
{
    auto v = (new Interp()).evalString("1");
    assert (v.word.intVal == 1);
}

/// Global expression tests
unittest
{
    assertInt("return 7", 7);
    assertInt("return 1 + 2", 3);
    assertInt("return 5 - 1", 4);
    assertInt("return 8 % 5", 3);
    assertInt("return -3", -3);
    assertInt("return +7", 7);
    assertInt("return 2 + 3 * 4", 14);
    assertInt("return 5 % 3", 2);

    assertFloat("return 3.5", 3.5);
    assertFloat("return 2.5 + 2", 4.5);
    assertFloat("return 2.5 + 2.5", 5);
    assertFloat("return 2.5 - 1", 1.5);
    assertFloat("return 2 * 1.5", 3);
    assertFloat("return 6 / 2.5", 2.4);
}

/// Global function calls
unittest
{
    assertInt("return function () { return 9; } ()", 9);
    assertInt("return function () { return 2 * 3; } ()", 6);
}

/// Argument passing test
unittest
{
    assertInt("return function (x) { return x + 3; } (5)", 8);
    assertInt("return function (x, y) { return x - y; } (5, 2)", 3);

    // Too many arguments
    assertInt("return function (x) { return x + 1; } (5, 9)", 6);

    // Too few arguments
    assertInt("return function (x, y) { return x - 1; } (4)", 3);
}

/// Local variable assignment
unittest
{
    assertInt("return function () { var x = 4; return x; } ()", 4);
    assertInt("return function () { var x = 0; return x++; } ()", 0);
    assertInt("return function () { var x = 0; return ++x; } ()", 1);
    assertInt("return function () { var x = 0; return x--; } ()", 0);
    assertInt("return function () { var x = 0; return --x; } ()", -1);
    assertInt("return function () { var x = 0; ++x; return ++x; } ()", 2);
    assertInt("return function () { var x = 0; return x++ + 1; } ()", 1);
    assertInt("return function () { var x = 1; return x = x++ % 2; } ()", 1);
}

/// Comparison and branching
unittest
{
    assertInt("if (true) return 1; else return 0;", 1);
    assertInt("if (false) return 1; else return 0;", 0);
    assertInt("if (3 < 7) return 1; else return 0;", 1);
    assertInt("if (5 < 2) return 1; else return 0;", 0);
    assertInt("if (1 < 1.5) return 1; else return 0;", 1);
    assertBool("3 <= 5", true);
    assertBool("5 <= 5", true);
    assertBool("7 <= 5", false);
 
    assertInt("return true? 1:0", 1);
    assertInt("return false? 1:0", 0);

    assertInt("return 0 || 2", 2);
    assertInt("return 1 || 2", 1);
    assertInt("return 0 || 0 || 3", 3);
    assertInt("return 0 || 2 || 3", 2);
    assertInt("if (0 || 2) return 1; else return 0;", 1);
    assertInt("if (1 || 2) return 1; else return 0;", 1);
    assertInt("if (0 || 0) return 1; else return 0;", 0);

    assertInt("return 0 && 2", 0);
    assertInt("return 1 && 2", 2);
    assertInt("return 1 && 2 && 3", 3);
    assertInt("return 1 && 0 && 3", 0);
    assertInt("if (0 && 2) return 1; else return 0;", 0);
    assertInt("if (1 && 2) return 1; else return 0;", 1);
}

/// Recursion
unittest
{
    assertInt(
        "
        return function (n)
        {
            var fact = function (fact, n)
            {
                if (n < 1)
                    return 1;
                else   
                    return n * fact(fact, n-1);
            };
                              
            return fact(fact, n);
        } (4);
        ",
        24
    );

    assertInt(
        "
        return function (n)
        {
            var fib = function (fib, n)
            {
                if (n < 2)
                    return n;
                else   
                    return fib(fib, n-1) + fib(fib, n-2);
            };
                              
            return fib(fib, n);
        } (6);
        ",
        8
    );
}

/// Loops
unittest
{
    assertInt(
        "
        return function ()
        {
            var i = 0;
            while (i < 10) ++i;
            return i;
        } ();
        ",
        10
    );

    assertInt(
        "
        return function ()
        {
            var i = 0;
            while (true)
            {
                if (i === 5)
                    break;
                ++i;
            }

            return i;
        } ();
        ",
        5
    );

    assertInt(
        "
        return function ()
        {
            var sum = 0;
            var i = 0;
            while (i < 10)
            {
                if ((i++ % 2) === 0)
                    continue;

                sum = sum + i;
            }

            return sum;
        } ();
        ",
        30
    );

    assertInt(
        "
        return function ()
        {
            var i = 0;
            do { i++; } while (i < 9)
            return i;
        } ();
        ",
        9
    );

    assertInt(
        "
        return function ()
        {
            for (var i = 0; i < 10; ++i);
            return i;
        } ();
        ",
        10
    );
}

/// Strings
unittest
{
    assertStr("return 'foo'", "foo");
    assertStr("return 'foo' + 'bar'", "foobar");
    assertStr("return 'foo' + 1", "foo1");
    assertStr("return 'foo' + true", "footrue");
    assertInt("return 'foo'? 1:0", 1);
    assertInt("return ''? 1:0", 0);
    assertInt("return ('foo' === 'foo')? 1:0", 1);
    assertInt("return ('foo' === 'f' + 'oo')? 1:0", 1);

    assertStr(
        "
        return function ()
        {
            var s = '';

            for (var i = 0; i < 5; ++i)
                s += i;

            return s;
        } ();
        ",
        "01234"
    );
}

// Typeof operator
unittest
{
    assertStr("return typeof 'foo'", "string");
    assertStr("return typeof 1", "number");
    assertStr("return typeof true", "boolean");
    assertStr("return typeof false", "boolean");
    assertStr("return typeof null", "object");
    assertInt("return (typeof 'foo' === 'string')? 1:0", 1);
}

/// Global scope, global object
unittest
{
    assertInt("a = 1; return a;", 1);
    assertInt("var a; a = 1; return a;", 1);
    assertInt("var a = 1; return a;", 1);
    assertInt("a = 1; b = 2; return a+b;", 3);

    assertInt("return a = 1,2;", 2);
    assertInt("a = 1,2; return a;", 1);
    assertInt("a = (1,2); return a;", 2);

    assertInt("f = function() { return 7; }; return f();", 7);
    assertInt("function f() { return 9; }; return f();", 9);

    assertInt(
        "
        function fib(n)
        {
            if (n < 2)
                return n;
            else   
                return fib(n-1) + fib(n-2);
        }
                          
        return fib(6);
        ",
        8
    );
}

/// In-place operators
unittest
{
    assertInt("a = 1; a += 2; return a;", 3);
    assertInt("a = 1; a += 4; a -= 3; return a;", 2);
    assertInt("a = 1; b = 3; a += b; return a;", 4);
    assertInt("a = 1; b = 3; return a += b;", 4);
    assertInt("function f() { var a = 0; a += 1; a += 1; return a; }; return f();", 2);
    assertInt("function f() { var a = 0; a += 2; a *= 3; return a; }; return f();", 6);
}

/// Object literals, property access, method calls
unittest
{
    assertInt("{}; return 1;", 1);
    assertInt("{x: 7}; return 1;", 1);
    assertInt("o = {}; o.x = 7; return 1;", 1);
    assertInt("o = {}; o.x = 7; return o.x;", 7);
    assertInt("o = {x: 9}; return o.x;", 9);
    assertInt("o = {x: 9}; o.y = 1; return o.x + o.y;", 10);
    assertInt("o = {x: 5}; o.x += 1; return o.x;", 6);
    assertInt("o = {x: 5}; return o.y? 1:0;", 0);

    // Function object property
    assertInt("function f() { return 1; }; f.x = 3; return f() + f.x;", 4);

    // Method call
    assertInt("o = {x:7, m:function() {return this.x;}}; return o.m();", 7);
}

/// New operator, prototype chain
unittest
{
    assertInt("function f() {}; o = new f(); return 0", 0);
    assertInt("function f() {}; o = new f(); return o? 1:0", 1);
    assertInt("function f() { g = this; }; o = new f(); return g? 1:0", 1);
    assertInt("function f() { this.x = 3 }; o = new f(); return o.x", 3);
    assertInt("function f() { return {y:7}; }; o = new f(); return o.y", 7);

    assertInt("function f() {}; return f.prototype? 1:0", 1);
    assertInt("function f() {}; f.prototype.x = 9; return f.prototype.x", 9);

    assertInt(
        "
        function f() {}
        f.prototype.x = 9;
        o = new f();
        return o.x;
        ",
        9
    );

    assertInt(
        "
        function f() {}
        f.prototype.x = 9;
        f.prototype.y = 1;
        o = new f();
        return o.x;
        ",
        9
    );

    assertInt(
        "
        function f() {}
        f.prototype.x = 9;
        f.prototype.y = 1;
        f.prototype.z = 2;
        o = new f();
        return o.x + o.y + o.z;
        ",
        12
    );
}

/// Array literals, array operations
unittest
{   
    assertInt("a = []; return 0", 0);
    assertInt("a = [1]; return 0", 0);
    assertInt("a = [1,2]; return 0", 0);
    assertInt("a = [1,2]; return a[0]", 1);
    assertInt("a = [1,2]; a[0] = 3; return a[0]", 3);
    assertInt("a = [1,2]; a[3] = 4; return a[1]", 2);
    assertInt("a = [1,2]; a[3] = 4; return a[3]", 4);
    assertInt("a = [1,2]; return a[3]? 1:0;", 0);
}

/// Inline IR
unittest
{
    assertInt("return $ir_add_i32(5,3);", 8);
    assertInt("return $ir_sub_i32(5,3);", 2);
    assertInt("return $ir_mul_i32(5,3);", 15);
    assertInt("return $ir_div_i32(5,3);", 1);
    assertInt("return $ir_mod_i32(5,3);", 2);
    assertInt("return $ir_eq_i32(3,3)? 1:0;", 1);
    assertInt("return $ir_eq_i32(3,2)? 1:0;", 0);
    assertInt("return $ir_ne_i32(3,5)? 1:0;", 1);
    assertInt("return $ir_ne_i32(3,3)? 1:0;", 0);
    assertInt("return $ir_lt_i32(3,5)? 1:0;", 1);
    assertInt("return $ir_ge_i32(5,5)? 1:0;", 1);

    assertInt(
        "
        function foo()
        {
            var o;
            if (o = $ir_add_i32_ovf(1, 2))
                return o;
            else
                return -1;
        }
        return foo();
        ",
        3
    );

    assertInt(
        "
        function foo()
        {
            var o;
            if (o = $ir_add_i32_ovf(0x7FFFFFFF, 1))
                return o;
            else
                return -1;
        }
        return foo();
        ",
        -1
    );

    assertInt(
        "
        function foo()
        {
            var o;
            if (o = $ir_add_i32_ovf(-0x80000000, -0x80000000))
                return o;
            else
                return -1;
        }
        return foo();
        ",
        -1
    );

    assertInt(
        "
        function foo()
        {
            var o;
            if (o = $ir_mul_i32_ovf(4, 4))
                return o;
            else
                return -1;
        }
        return foo();
        ",
        16
    );

    assertInt(
        "
        var ptr = $ir_heap_alloc(16);
        $ir_store_u8(ptr, 0, 77);
        return $ir_load_u8(ptr, 0);
        ",
        77
    );
}

/// Runtime functions
unittest
{
    assertInt("$rt_toBool(0)? 1:0", 0);
    assertInt("$rt_toBool(5)? 1:0", 1);
    assertInt("$rt_toBool(true)? 1:0", 1);
    assertInt("$rt_toBool(false)? 1:0", 0);
    assertInt("$rt_toBool(null)? 1:0", 0);
    assertInt("$rt_toBool('')? 1:0", 0);
    assertInt("$rt_toBool('foo')? 1:0", 1);

    assertStr("$rt_toString(5)", "5");
    assertStr("$rt_toString('foo')", "foo");
    assertStr("$rt_toString({toString: function(){return 's';}})", "s");

    assertInt("$rt_add(5, 3)", 8);
    assertFloat("$rt_add(5, 3.5)", 8.5);
    assertStr("$rt_add(5, 'bar')", "5bar");
    assertStr("$rt_add('foo', 'bar')", "foobar");

    assertInt("$rt_sub(5, 3)", 2);
    assertFloat("$rt_sub(5, 3.5)", 1.5);

    assertInt("$rt_mul(3, 5)", 15);
    assertFloat("$rt_mul(5, 1.5)", 7.5);
    assertFloat("$rt_mul(0xFFFF, 0xFFFF)", 4294836225);

    assertFloat("$rt_div(15, 3)", 5);
    assertFloat("$rt_div(15, 1.5)", 10);

    assertInt("isNaN(3)? 1:0", 0);
    assertInt("isNaN(3.5)? 1:0", 0);
    assertInt("isNaN(NaN)? 1:0", 1);
    assertStr("$rt_toString(NaN);", "NaN");
}

/// Stdlib Math library
unittest
{
    assertFloat("Math.cos(0)", 1);
    assertFloat("Math.cos(Math.PI)", -1);
    assertInt("isNaN(Math.cos('f'))? 1:0", 1);

    assertFloat("Math.sin(0)", 0);
    assertFloat("Math.sin(Math.PI)", 0);

    assertFloat("Math.sqrt(4)", 2);

    assertInt("Math.pow(2, 0)", 1);
    assertInt("Math.pow(2, 4)", 16);
    assertInt("Math.pow(2, 8)", 256);
}

/// Basic test programs
unittest
{
    auto interp = new Interp();

    interp.load("programs/fib/fib.js");
    interp.assertInt("fib(8);", 21);

    interp.load("programs/nested_loops/nested_loops.js");
    interp.assertInt("foo(10);", 510);
}

/// SunSpider benchmarks
unittest
{
    auto interp = new Interp();

    // FIXME: unsupported opcode cmp_eq
    //interp.load("programs/sunspider/controlflow-recursive.js");

    //interp.load("programs/sunspider/math-partial-sums.js");
}

