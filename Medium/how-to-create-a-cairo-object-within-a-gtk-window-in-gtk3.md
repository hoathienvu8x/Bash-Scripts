---
title: How to create a cairo object within a gtk window in GTK+3
link: https://stackoverflow.com/questions/57699050/how-to-create-a-cairo-object-within-a-gtk-window-in-gtk3
author: Parsa Mousavi & DarkTrick & OldUrologist
---

I'm trying to use cairo to draw some arcs but gcc warns me that *`gdk_cairo_create()`
is deprecated. Use `gdk_window_begin_draw_frame()` and `gdk_drawing_context_get_cairo_context()`
instead* .To get around this I did some research and found out that for `gdk_window_begin_draw_frame()`
I need "GdkWindow". I've always been using GtkWidget for my windows so I
need to convert `"GtkWidget"` to `"GdkWindow"`, but `gtk_widget_get_window()`
returns `NULL` and causes segfault.

```c++
#include <gtk/gtk.h>
#include <cairo.h>
void main(int argc , char **argv){
    gtk_init(&argc , &argv);
    GtkWidget *win;
    GdkWindow *gdkwin;
    GdkDrawingContext *dc;

    cairo_region_t *region;

    cairo_t *cr;

    win = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    region = cairo_region_create();

    gdkwin = gtk_widget_get_window(GTK_WIDGET(win));

    //Here gdkwin should contain a GdkWindow but it's NULL.

    gc = gdk_window_begin_draw_frame(gdkwin , (const cairo_region_t*)&region);
    ...
    ...
```

Here's the runtime errors:

```bash
(a.out:6852): Gdk-CRITICAL **: 23:53:06.042: gdk_window_begin_draw_frame: assertion 'GDK_IS_WINDOW (window)' failed

(a.out:6852): Gdk-CRITICAL **: 23:53:06.042: gdk_drawing_context_get_cairo_context: assertion 'GDK_IS_DRAWING_CONTEXT (context)' failed
Segmentation fault
```

I want to get a cairo object and use it for `cairo_arc()`. The below is the
complete source code to get Cairo working under GTK 3.

It should be compilable as is.As the others already pointed out, you have
to use the draw signal to make things work.

```c++
#include <gtk/gtk.h>
#include <cairo.h>

// ------------------------------------------------------------

gboolean on_draw (GtkWidget *widget, GdkEventExpose *event, gpointer data) {
    // "convert" the G*t*kWidget to G*d*kWindow (no, it's not a GtkWindow!)
    GdkWindow* window = gtk_widget_get_window(widget);

    cairo_region_t * cairoRegion = cairo_region_create();

    GdkDrawingContext * drawingContext;
    drawingContext = gdk_window_begin_draw_frame (window,cairoRegion);
    {
        // say: "I want to start drawing"
        cairo_t * cr = gdk_drawing_context_get_cairo_context (drawingContext);
        { // do your drawing
            cairo_move_to(cr, 30, 30);
            cairo_set_font_size(cr,15);
            cairo_show_text(cr, "hello world");
        }

        // say: "I'm finished drawing
        gdk_window_end_draw_frame(window,drawingContext);
    }

    // cleanup
    cairo_region_destroy(cairoRegion);

    return FALSE;
 }

// ------------------------------------------------------------

int main (int argc, char * argv[]) {
    gtk_init(&argc, &argv);

    GtkWindow * window;
    { // window setup
        window = (GtkWindow*)gtk_window_new(GTK_WINDOW_TOPLEVEL);
        gtk_window_set_default_size (window, 200, 200);
        gtk_window_set_position (window, GTK_WIN_POS_CENTER);
        gtk_window_set_title (window, "Drawing");

        g_signal_connect(window, "destroy", gtk_main_quit, NULL);
    }

    // create the are we can draw in
    GtkDrawingArea* drawingArea;
    {
        drawingArea = (GtkDrawingArea*) gtk_drawing_area_new();
        gtk_container_add(GTK_CONTAINER(window), (GtkWidget*)drawingArea);

        g_signal_connect((GtkWidget*)drawingArea, "draw", G_CALLBACK(on_draw), NULL);
    }

    gtk_widget_show_all ((GtkWidget*)window);
    gtk_main();

    return 0;
}

 // ------------------------------------------------------------
```

The Dark Trick's program is complete. He uses the functions as follows,

```c++
GdkWindow* window = gtk_widget_get_window (widget);
cairo_region_t *cairoRegion = cairo_region_create();
GdkDrawingContext *drawingContext;
drawingContext = gdk_window_begin_draw_frame (window, cairoRegion);
cairo_t *cr = gdk_drawing_context_get_cairo_context (drawingContext);
```

But I am using the the functions as follows,

```c++
GdkWindow *window = gtk_widget_get_window(widget);
cairo_rectangle_int_t cairoRectangle = {0, 0, 200, 200};
cairo_region_t *cairoRegion = cairo_region_create_rectangle (&cairoRectangle);
GdkDrawingContext *drawingContext;
drawingContext = gdk_window_begin_draw_frame (window,cairoRegion);
cairo_t *cr = gdk_drawing_context_get_cairo_context (drawingContext);
```
