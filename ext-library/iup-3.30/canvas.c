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


WD_HCANVAS
wdCreateCanvasWithPaintStruct(HWND hWnd, PAINTSTRUCT* pPS, DWORD dwFlags)
{
    RECT rect;

    GetClientRect(hWnd, &rect);

    {
        BOOL use_doublebuffer = (dwFlags & WD_CANVAS_DOUBLEBUFFER);
        gdix_canvas_t* c;

        c = gdix_canvas_alloc(pPS->hdc, (use_doublebuffer ? &pPS->rcPaint : NULL),
                    rect.right, (dwFlags & WD_CANVAS_LAYOUTRTL));
        if(c == NULL) {
            WD_TRACE("wdCreateCanvasWithPaintStruct: gdix_canvas_alloc() failed.");
            return NULL;
        }
        return (WD_HCANVAS) c;
    }
}

WD_HCANVAS
wdCreateCanvasWithHDC(HDC hDC, const RECT* pRect, DWORD dwFlags)
{
    {
        BOOL use_doublebuffer = (dwFlags & WD_CANVAS_DOUBLEBUFFER);
        gdix_canvas_t* c;

        c = gdix_canvas_alloc(hDC, (use_doublebuffer ? pRect : NULL),
                pRect->right - pRect->left, (dwFlags & WD_CANVAS_LAYOUTRTL));
        if(c == NULL) {
            WD_TRACE("wdCreateCanvasWithHDC: gdix_canvas_alloc() failed.");
            return NULL;
        }
        return (WD_HCANVAS) c;
    }
}

void
wdDestroyCanvas(WD_HCANVAS hCanvas)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;

        gdix_vtable->fn_DeleteStringFormat(c->string_format);
        gdix_vtable->fn_DeletePen(c->pen);
        gdix_vtable->fn_DeleteGraphics(c->graphics);

        if(c->real_dc != NULL) {
            HBITMAP mem_bmp;

            mem_bmp = SelectObject(c->dc, c->orig_bmp);
            DeleteObject(mem_bmp);
            DeleteObject(c->dc);
        }

        free(c);
    }
}

void
wdBeginPaint(WD_HCANVAS hCanvas)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        SetLayout(c->dc, 0);
    }
}

BOOL
wdEndPaint(WD_HCANVAS hCanvas)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;

        /* If double-buffering, blit the memory DC to the display DC. */
        if(c->real_dc != NULL)
            BitBlt(c->real_dc, c->x, c->y, c->cx, c->cy, c->dc, 0, 0, SRCCOPY);

        SetLayout(c->real_dc, c->dc_layout);

        /* For GDI+, disable caching. */
        return FALSE;
    }
}

BOOL
wdResizeCanvas(WD_HCANVAS hCanvas, UINT uWidth, UINT uHeight)
{
    {
        /* Actually we should never be here as GDI+ back-end never allows
         * caching of the canvas so there is no need to ever resize it. */
        WD_TRACE("wdResizeCanvas: Not supported (GDI+ back-end).");
        return FALSE;
    }
}

HDC
wdStartGdi(WD_HCANVAS hCanvas, BOOL bKeepContents)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        int status;
        HDC dc;

        status = gdix_vtable->fn_GetDC(c->graphics, &dc);
        if(status != 0) {
            WD_TRACE_ERR_("wdStartGdi: GdipGetDC() failed.", status);
            return NULL;
        }

        SetLayout(dc, c->dc_layout);

        if(c->dc_layout & LAYOUT_RTL)
            SetViewportOrgEx(dc, c->x + c->cx - (c->width-1), -c->y, NULL);

        return dc;
    }
}

void
wdEndGdi(WD_HCANVAS hCanvas, HDC hDC)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;

        if(c->rtl)
            SetLayout(hDC, 0);
        gdix_vtable->fn_ReleaseDC(c->graphics, hDC);
    }
}

void
wdClear(WD_HCANVAS hCanvas, WD_COLOR color)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        gdix_vtable->fn_GraphicsClear(c->graphics, color);
    }
}

void
wdSetClip(WD_HCANVAS hCanvas, const WD_RECT* pRect, const WD_HPATH hPath)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        int mode;

        if(pRect == NULL  &&  hPath == NULL) {
            gdix_vtable->fn_ResetClip(c->graphics);
            return;
        }

        mode = dummy_CombineModeReplace;

        if(pRect != NULL) {
            gdix_vtable->fn_SetClipRect(c->graphics, pRect->x0, pRect->y0,
                             pRect->x1, pRect->y1, mode);
            mode = dummy_CombineModeIntersect;
        }

        if(hPath != NULL)
            gdix_vtable->fn_SetClipPath(c->graphics, (void*) hPath, mode);
    }
}

void
wdRotateWorld(WD_HCANVAS hCanvas, float cx, float cy, float fAngle)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;

        gdix_vtable->fn_TranslateWorldTransform(c->graphics, cx, cy, dummy_MatrixOrderPrepend);
        gdix_vtable->fn_RotateWorldTransform(c->graphics, fAngle, dummy_MatrixOrderPrepend);
        gdix_vtable->fn_TranslateWorldTransform(c->graphics, -cx, -cy, dummy_MatrixOrderPrepend);
    }
}

void
wdTranslateWorld(WD_HCANVAS hCanvas, float dx, float dy)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        gdix_vtable->fn_TranslateWorldTransform(c->graphics, dx, dy, dummy_MatrixOrderAppend);
    }
}

void
wdResetWorld(WD_HCANVAS hCanvas)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        gdix_reset_transform(c);
    }
}

