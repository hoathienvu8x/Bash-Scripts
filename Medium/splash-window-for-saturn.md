---
title: Splash window for Saturn
link: https://element90.wordpress.com/2012/04/03/splash-window-for-saturn/
author: Element90 Fractals
---

This post is about programming in C++ and its relation to fractals is only
due to the program involved being used to use fractal images. The tag line
for this blog does include "other stuff" and this post is definitely other stuff.

One of things I had intended to include in Saturn was a splash window to
be displayed while Saturn performed its initialisation. Saturn holds its
configuration in two XML files `config.xml` and `colours.xml`, the first file
holds the current state of each of the fractal types supported and colours.xml
holds Saturn's collection of colour maps. Currently my installation of Saturn
has over 500 colour maps and it takes Saturn a significant amount of time
to load the data held in these files (16 seconds when built for debugging).

User's are inherently impatient, myself included, so a significant delay
between launching an application and its window appearing is annoying,
there are many programs that display a splash window to give the user an
indication that yes the program was launched and it will indeed appear after
some essential stuff has been performed. As a software engineer I've commonly
seen splash windows for such programs as NetBeans, MonoDevelop and Microsoft's
Visual Studio, other programs I've seen that use splash screens are Ultra
Fractal and the Fractal Science Kit.

Saturn is written in C++ and uses the Gtkmm tool kit and as splash windows
are a common feature that software engineer's are likely too want guidance
must surely be available on the internet, well, not a bit of it. No tutorials,
just a few questions here and there giving tantalising glimpses how to implement
a splash screen. I used some of the information I found which wasn't much
and succeeded in getting a splash window displayed, however, most of the
time it was only displayed as a light grey rectangle and only occasionally
was the the pretty picture displayed.

I have however succeeded in displaying a splash window consistently and
since there is so little information on the web on how to do this I indeed
to share my solution. First of all for a splash window some sort of picture
is required here is mine:

![splash](https://element90.files.wordpress.com/2012/04/splash.png)

Before I go any further I must say that example code will be based on `Gtkmm 2`
and not on the newer Gtkmm 3 this is because I haven't yet migrated to `Gtkmm 3`.
Migration must be performed soon as many of the classes I'm using have been
deprecated such as `Gtk::Main` and `Glib::Thread`.

Having got a picture, in my case splash.png,  some means of displaying it
is required, but what? It took a while to find, the answer is a window
(`Gtk::Window`) containing an image widget (`Gtk::Image`). The key to the
splash window is to have an "undecorated" window i.e. no border and certainly
no buttons.

Since we are using C++ a Splash class is derived from `Gtk::Window`.

```c++
class Splash : public Gtk::Window
{
public:
    Splash(void);
    ~Splash(void);

    bool display(void);

private:
    Splash(void);
    Splash(const Splash& orig);

    virtual bool on_expose_event(GtkExposeEvent *event);
    virtual void on_realize(void);

    void thread(void);

    Gtk::Image *m_image;
    int m_width;
    int m_height;
};
```

Which is implemented as:

```c++
Splash::Splash(void)
:
Gtk::Window(),
m_width(450),
m_height(500)
{
    set_position(Gtk::WIN_POS_CENTER);  // Display window at the centre of the screen
    set_decoration(false);              // Display window WITHOUT a border and buttons
    set_size_request(m_width, m_height);
    add(m_image);
}

Splash::~Splash(void)
{
}

bool Splash::display(void)
{
    bool ok = false;
    //
    // I'll only show here the essential code here, the splash.png file must loaded here where the file
    // is located and how failure to find it is handled is up to you ...
    auto pixbuf = Gdk::Pixbuf::create(Glib::current_directory() + "/splash.png");
    auto scaled_pixbuf = pixbuf->scale_simple(m_width, m_height, Gdk::\INTERP_HYPER);
    m_scale->set(scaled_pixbuf);
    ok = true;
    return ok;
}

bool Splash::on_expose_event(GtkExposeEvent *event)
{
    auto pixbuf = m_image->get_pixbuf();
    get_window->draw_pixbuf(get_style()->get_black_gc(),
                               pixbuf,
                               0,
                               0,
                               0,
                               0,
                               m_width,
                               m_height,
                               0,
                               0);
    return false;
}

void Splash::on_realize(void)
{
    Gtk::Window::on_realize();
    auto id = Glib::Thread::create(sigc::mem_fun(*this, &Splash::thread), false);
}

void Splash::thread(void)
{
    // put program initialisation code here in Saturn this consists 
    // of loading the fractal configuration from config.xml and
    // colour maps from colours.xml
    Gtk::Main::quit();  // tell current main loop to exit
}
```

The initialisation code is run in a thread when the Splash object receives
the realize signal and the picture is displayed on receipt of an expose signal.
If the splash window is covered and then uncovered an expose signal is sent
so the splash window is redrawn. When the initialisation is complete `Gtk::Main::quit()`
is called which is clue to how the Splash class is used.

Here is use of the Splash class in a much simplified Saturn main.cc.

```c++
//
// the usual #includes ... if you're interested in code for splash windows
// you know what these are ...
//

int main(int argc, char **argv)
{
    Glib::thread_init();
    Gtk::Main kit(argc, argv);

    // Code to find the glade file containing Saturn's user interface, a
    // Glib::RefPtr will point 
    // to the widgets loaded from the glade file.

    Splash *splash;
    if (splash->display())
    {
         Gtk::Main::run(*splash);
    }
    else
    {
        // initialisation code that would have be called if the splash window
        // picture was found
    }
    delete splash; // no longer required
    Gtk::Window *window;
    glade->get_widget("window", window);
    Gtk::Main::run(*window);
    // code to save current state of fractals and colour maps
    return 0;
}
```

As can be seen the Gtk main loop is used twice. Providing the picture used
for the splash window is found the event loop is entered with just the splash
window. There are no buttons so the window can't closed by the user. As
the window is handled by the main loop the window is redrawn when necessary,
when the initialisation code completes `Gtk::Main::quit()` is called causing
the main loop to exit, the splash object is no longer required and can be
deleted. Now that the initialisation of Saturn is complete the widget for
the man window is requested from glade and the main loop proper is entered,
when Saturn is closed the main loop exits and code to update Saturn's configuration
files is run.

The proper Saturn main function is much longer and will display an error
window if its glade file is not found.

I've found and fixed a minor bug in version 2.0.0, I need to build Saturn
on Windows to make sure that the splash window also works there, I'll also
fix any more minor bugs if I find them in the next day or so when version
2.0.1 will be released with the splash window included.
