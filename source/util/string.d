/*****************************************************************************
*
*                      Higgs JavaScript Virtual Machine
*
*  This file is part of the Higgs project. The project is distributed at:
*  https://github.com/maximecb/Higgs
*
*  Copyright (c) 2011, Maxime Chevalier-Boisvert. All rights reserved.
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

module util.string;

import std.string;
import std.array;

/**
Indent each line of a text string
*/
string indent(string input, string indentStr = "    ")
{
    auto output = appender!string();

    if (input.length > 0)
        output.put(indentStr);

    for (size_t i = 0; i < input.length; ++i)
    {
        auto ch = input[i];

        output.put(ch);

        if (ch == '\n' && i != input.length - 1)
            output.put(indentStr);
    }

    return output.data;
}

/**
Escape a JavaScript string for output
*/
wstring escapeJSString(wstring input)
{
    auto output = appender!wstring();

    for (size_t i = 0; i < input.length; ++i)
    {
        auto ch = input[i];

        switch (ch)
        {
            case '\0': output.put("\\0"); break;
            case '\r': output.put("\\r"); break;
            case '\n': output.put("\\n"); break;
            case '\t': output.put("\\t"); break;
            case '\v': output.put("\\v"); break;
            case '\f': output.put("\\f"); break;
            case '\\': output.put("\\\\"); break;
            case '"': output.put("\\\""); break;
            case '\'': output.put("\\\'"); break;

            default:
            if (ch < 32 || ch > 126)
                output.put(format("\\u%04x", cast(int)ch));
            else
                output.put(ch);
        }
    }

    return output.data;
}

/**
Escape a D string for output
*/
string escapeDString(string input)
{
    auto output = appender!string();

    for (size_t i = 0; i < input.length; ++i)
    {
        auto ch = input[i];

        switch (ch)
        {
            case '\0': output.put("\\0"); break;
            case '\r': output.put("\\r"); break;
            case '\n': output.put("\\n"); break;
            case '\t': output.put("\\t"); break;
            case '\v': output.put("\\v"); break;
            case '\f': output.put("\\f"); break;
            case '\\': output.put("\\\\"); break;
            case '"': output.put("\\\""); break;
            case '\'': output.put("\\\'"); break;

            default:
            if (ch < 32 || ch > 126)
                output.put(format("\\u%04x", cast(int)ch));
            else
                output.put(ch);
        }
    }

    return output.data;
}

