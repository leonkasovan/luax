/*
 * WinDrawLib
 * Copyright (c) 2015-2016 Martin Mitas
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#include "misc.h"
#include "backend-gdix.h"
#include "lock.h"


void
wdFillEllipse(WD_HCANVAS hCanvas, WD_HBRUSH hBrush, float cx, float cy, float rx, float ry)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        float dx = 2.0f * rx;
        float dy = 2.0f * ry;

        gdix_vtable->fn_FillEllipse(c->graphics, (void*) hBrush, cx - rx, cy - ry, dx, dy);
    }
}

void
wdFillPath(WD_HCANVAS hCanvas, WD_HBRUSH hBrush, const WD_HPATH hPath)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;

        gdix_vtable->fn_FillPath(c->graphics, (void*) hBrush, (void*) hPath);
    }
}

void
wdFillEllipsePie(WD_HCANVAS hCanvas, WD_HBRUSH hBrush, float cx, float cy, float rx, float ry,
          float fBaseAngle, float fSweepAngle)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        float dx = 2.0f * rx;
        float dy = 2.0f * ry;

        gdix_vtable->fn_FillPie(c->graphics, (void*) hBrush,
                cx - rx, cy - ry, dx, dy, fBaseAngle, fSweepAngle);
    }
}

void
wdFillRect(WD_HCANVAS hCanvas, WD_HBRUSH hBrush,
           float x0, float y0, float x1, float y1)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        float tmp;

        /* Make sure x0 <= x1 and y0 <= y1. */
        if(x0 > x1) { tmp = x0; x0 = x1; x1 = tmp; }
        if(y0 > y1) { tmp = y0; y0 = y1; y1 = tmp; }

        gdix_vtable->fn_FillRectangle(c->graphics, (void*) hBrush,
                x0, y0, x1 - x0, y1 - y0);
    }
}

