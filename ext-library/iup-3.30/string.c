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
wdDrawString(WD_HCANVAS hCanvas, WD_HFONT hFont, const WD_RECT* pRect,
             const WCHAR* pszText, int iTextLength, WD_HBRUSH hBrush,
             DWORD dwFlags)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        dummy_GpRectF r;
        dummy_GpFont* f = (dummy_GpFont*) hFont;
        dummy_GpBrush* b = (dummy_GpBrush*) hBrush;

        if(c->rtl) {
            gdix_rtl_transform(c);
            r.x = (float)(c->width-1) - pRect->x1;
        } else {
            r.x = pRect->x0;
        }
        r.y = pRect->y0;
        r.w = pRect->x1 - pRect->x0;
        r.h = pRect->y1 - pRect->y0;

        gdix_canvas_apply_string_flags(c, dwFlags);
        gdix_vtable->fn_DrawString(c->graphics, pszText, iTextLength,
                f, &r, c->string_format, b);

        if(c->rtl)
            gdix_rtl_transform(c);
    }
}

void
wdMeasureString(WD_HCANVAS hCanvas, WD_HFONT hFont, const WD_RECT* pRect,
                const WCHAR* pszText, int iTextLength, WD_RECT* pResult,
                DWORD dwFlags)
{
    {
        gdix_canvas_t* c = (gdix_canvas_t*) hCanvas;
        dummy_GpRectF r;
        dummy_GpFont* f = (dummy_GpFont*) hFont;
        dummy_GpRectF br;

        if(c->rtl) {
            gdix_rtl_transform(c);
            r.x = (float)(c->width-1) - pRect->x1;
        } else {
            r.x = pRect->x0;
        }
        r.y = pRect->y0;
        r.w = pRect->x1 - pRect->x0;
        r.h = pRect->y1 - pRect->y0;

        gdix_canvas_apply_string_flags(c, dwFlags);
        gdix_vtable->fn_MeasureString(c->graphics, pszText, iTextLength, f, &r,
                                c->string_format, &br, NULL, NULL);

        if(c->rtl)
            gdix_rtl_transform(c);

        pResult->x0 = br.x;
        pResult->y0 = br.y;
        pResult->x1 = br.x + br.w;
        pResult->y1 = br.y + br.h;
    }
}

float
wdStringWidth(WD_HCANVAS hCanvas, WD_HFONT hFont, const WCHAR* pszText)
{
    const WD_RECT rcClip = { 0.0f, 0.0f, 10000.0f, 10000.0f };
    WD_RECT rcResult;

    wdMeasureString(hCanvas, hFont, &rcClip, pszText, wcslen(pszText),
                &rcResult, WD_STR_LEFTALIGN | WD_STR_NOWRAP);
    return WD_ABS(rcResult.x1 - rcResult.x0);
}

float
wdStringHeight(WD_HFONT hFont, const WCHAR* pszText)
{
    WD_FONTMETRICS metrics;

    wdFontMetrics(hFont, &metrics);
    return metrics.fLeading;
}
