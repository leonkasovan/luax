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


WD_HPATH
wdCreatePath(WD_HCANVAS hCanvas)
{
    {
        dummy_GpPath* p;
        int status;

        status = gdix_vtable->fn_CreatePath(dummy_FillModeAlternate, &p);
        if(status != 0) {
            WD_TRACE("wdCreatePath: GdipCreatePath() failed. [%d]", status);
            return NULL;
        }

        return (WD_HPATH) p;
    }
}

WD_HPATH
wdCreatePolygonPath(WD_HCANVAS hCanvas, const WD_POINT* pPoints, UINT uCount)
{
    WD_HPATH p;

    p = wdCreatePath(hCanvas);
    if(p == NULL) {
        WD_TRACE("wdCreatePolygonPath: wdCreatePath() failed.");
        return NULL;
    }

    if(uCount > 0) {
        WD_PATHSINK sink;
        UINT i;

        if(!wdOpenPathSink(&sink, p)) {
            WD_TRACE("wdCreatePolygonPath: wdOpenPathSink() failed.");
            wdDestroyPath(p);
            return NULL;
        }

        wdBeginFigure(&sink, pPoints[0].x, pPoints[0].y);
        for(i = 1; i < uCount; i++)
            wdAddLine(&sink, pPoints[i].x, pPoints[i].y);
        wdEndFigure(&sink, TRUE);

        wdClosePathSink(&sink);
    }

    return p;
}

WD_HPATH
wdCreateRoundedRectPath(WD_HCANVAS hCanvas, const WD_RECT* prc, float r)
{
    WD_HPATH    p;
    WD_PATHSINK sink;
    float       w_2, h_2;

    /* Adjust the radius according to the maximum size allowed */
    w_2 = (prc->x1 - prc->x0) / 2.f + 0.5f;
    h_2 = (prc->y1 - prc->y0) / 2.f + 0.5f;

    if (r > w_2) r = w_2;
    if (r > h_2) r = h_2;

    /* Create the path */
    p = wdCreatePath(hCanvas);
    if(p == NULL) {
        WD_TRACE("wdCreateRoundRectPath: wdCreatePath() failed.");
        return NULL;
    }

    if(!wdOpenPathSink(&sink, p))
    {
        WD_TRACE("wdCreateRoundRectPath: wdOpenPathSink() failed.");
        wdDestroyPath(p);
        return NULL;
    }

    wdBeginFigure(&sink, prc->x0+r, prc->y0);

    wdAddLine(&sink, prc->x1-r, prc->y0);
    wdAddArc (&sink, prc->x1-r, prc->y0+r, 90.0f);
    wdAddLine(&sink, prc->x1,   prc->y1-r);
    wdAddArc (&sink, prc->x1-r, prc->y1-r, 90.0f);
    wdAddLine(&sink, prc->x0+r, prc->y1);
    wdAddArc (&sink, prc->x0+r, prc->y1-r, 90.0f);
    wdAddLine(&sink, prc->x0,   prc->y0+r);
    wdAddArc (&sink, prc->x0+r, prc->y0+r, 90.0f);

    wdEndFigure(&sink, TRUE);
    wdClosePathSink(&sink);

    return p;
}

void
wdDestroyPath(WD_HPATH hPath)
{
    {
        gdix_vtable->fn_DeletePath((dummy_GpPath*) hPath);
    }
}

BOOL
wdOpenPathSink(WD_PATHSINK* pSink, WD_HPATH hPath)
{
    {
        /* GDI+ doesn't have any concept of path sink as Direct2D does, it
         * operates directly with the path object. */
        pSink->pData = (void*) hPath;
        return TRUE;
    }
}

void
wdClosePathSink(WD_PATHSINK* pSink)
{
    {
        /* noop */
    }
}

void
wdBeginFigure(WD_PATHSINK* pSink, float x, float y)
{
    {
        gdix_vtable->fn_StartPathFigure(pSink->pData);
    }

    pSink->ptEnd.x = x;
    pSink->ptEnd.y = y;
}

void
wdEndFigure(WD_PATHSINK* pSink, BOOL bCloseFigure)
{
    {
        if(bCloseFigure)
            gdix_vtable->fn_ClosePathFigure(pSink->pData);
    }
}

void
wdAddLine(WD_PATHSINK* pSink, float x, float y)
{
    {
        gdix_vtable->fn_AddPathLine(pSink->pData,
                        pSink->ptEnd.x, pSink->ptEnd.y, x, y);
    }

    pSink->ptEnd.x = x;
    pSink->ptEnd.y = y;
}

void
wdAddArc(WD_PATHSINK* pSink, float cx, float cy, float fSweepAngle)
{
    float ax = pSink->ptEnd.x;
    float ay = pSink->ptEnd.y;
    float xdiff = ax - cx;
    float ydiff = ay - cy;
    float r;
    float base_angle;

    r = sqrtf(xdiff * xdiff + ydiff * ydiff);

    /* Avoid undefined case for atan2f(). */
    if(r < 0.001f)
        return;

    base_angle = atan2f(ydiff, xdiff) * (180.0f / WD_PI);

    {
        float d = 2.0f * r;
        float sweep_rads = (base_angle + fSweepAngle) * (WD_PI / 180.0f);

        gdix_vtable->fn_AddPathArc(pSink->pData, cx - r, cy - r, d, d, base_angle, fSweepAngle);
        pSink->ptEnd.x = cx + r * cosf(sweep_rads);
        pSink->ptEnd.y = cy + r * sinf(sweep_rads);
    }
}

