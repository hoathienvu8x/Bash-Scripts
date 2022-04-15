---
title: Ported fill and stroke Cairo drawing example on Zetcode.com to GTK+3
link: https://chrisheydrick.com/2012/06/21/ported-fill-and-stroke-cairo-drawing-example-on-zetcode-com-to-gtk3/
author: Chris Heydrick
---

If you do any searching for Cairo or GTK+ tutorials, you'll eventually wind
up on [zetcode.com](http://zetcode.com/). I'd be content with only a fraction
of this guy's talent for explaining difficult subject matters with such brevity
and clarity. It's not coincidence that much of my code style matches his. 
 
That said, his [GTK+](http://zetcode.com/tutorials/gtktutorial/) and
[Cairo](http://zetcode.com/tutorials/cairographicstutorial/) tutorials are
a bit out of date. The [migration from GTK+2 to GTK+3](http://developer.gnome.org/gtk3/stable/migrating.html)
was pretty dramatic. There is no longer an "expose-event" signal to trigger
redrawing of a window. It's been replaced by "draw", and the prototype for
the callback changed, too. I've been meaning to learn Cairo now that GTK+
is completely in bed with it, so I thought I'd tackle porting the
[fill and stroke example](http://zetcode.com/tutorials/cairographicstutorial/basicdrawing/)
on zetcode.com to be GTK+3 compatible. 

```c++
/* This is a GTK+3 ported version of the Basic Drawing
 * fill and stroke Cairo tutorial at zetcode.com
 * http://zetcode.com/tutorials/cairographicstutorial/basicdrawing/
 */

#include <stdio.h>
#include <stdlib.h>
#include <cairo.h>
#include <gtk/gtk.h>
#include <math.h>

gboolean on_draw_event (GtkWidget *widget, cairo_t *cr, gpointer user_data)
{
  /* http://stackoverflow.com/questions/8722084/using-cairo-with-gtk3 */

  cr = gdk_cairo_create(gtk_widget_get_window(widget));

  int width, height;
  gtk_window_get_size(GTK_WINDOW(widget), &width, &height);
  cairo_set_line_width(cr, 9);

  cairo_set_source_rgb(cr, 0.69, 0.19, 0);
  cairo_arc(cr, width/2, height/2, (width < height ? width : height) / 2 - 10, 0, 2 * M_PI);
  cairo_stroke_preserve(cr);

  cairo_set_source_rgb(cr, 0.3, 0.4, 0.6);
  cairo_fill(cr);

  cairo_destroy(cr);

  return FALSE;
}

int main (int argc, char *argv[])
{
  GtkWidget *window;

  gtk_init(&argc, &argv);

  window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

  g_signal_connect(G_OBJECT(window), "draw", G_CALLBACK(on_draw_event), NULL);
  g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);

  gtk_window_set_position(GTK_WINDOW(window), GTK_WIN_POS_CENTER);
  gtk_window_set_default_size(GTK_WINDOW(window), 200, 150);

  gtk_widget_set_app_paintable(window, TRUE);
  gtk_widget_show_all(window);

  gtk_main();

  return 0;
}
```

No big deal here, only three changes required.

_1. Change the signal connection_

```c++
g_signal_connect(G_OBJECT(window), "expose-event", G_CALLBACK(on_expose_event), NULL);
```
to
```c++
g_signal_connect(G_OBJECT(window), "draw", G_CALLBACK(on_draw_event), NULL);
```
because there is no "expose-event" signal anymore.

_2. Change the event callback prototype_

```c++
on_expose_event (GtkWidget *widget, GdkEventExpose *event, gpointer data)
```
to
```c++
on_draw_event(GtkWidget *widget, cairo_t *cr, gpointer data)
```
and note that the names on_draw_event and on_expose_event are arbitrary.
It's common in most examples to name them as such.

_3. In the draw event callback change_
```c++
cr = gdk_cairo_create (widget->window);
```
to
```c++
cr = gdk_cairo_create(gtk_widget_get_window(widget));
```
because the window member is considered private now. You need to use the
function `gtk_widget_get_window()` to get a pointer to the window. 
 
I really want to get a grip on Cairo since it's the new way forward in Gnome
development. Porting the zetcode.com examples might help start me out.
