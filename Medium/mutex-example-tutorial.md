---
title: Mutex example / tutorial?
link: https://stackoverflow.com/questions/4989451/mutex-example-tutorial
---

I'm new to multithreading, and was trying to understand how mutexes work.
Did a lot of Googling but it still left some doubts of how it works because
I created my own program in which locking didn't work.

One absolutely non-intuitive syntax of the mutex is `pthread_mutex_lock( &mutex1 );`,
where it looks like the mutex is being locked, when what I really want to
lock is some other variable. Does this syntax mean that locking a mutex locks
a region of code until the mutex is unlocked? Then how do threads know that
the region is locked? [*UPDATE: Threads know that the region is locked, by*
[Memory Fencing](http://en.wikipedia.org/wiki/Memory_barrier#Multithreaded_programming_and_memory_visibility) ].
And isn't such a phenomenon supposed to be called critical section? [*UPDATE:
Critical section objects are available in Windows only, where the objects
are faster than mutexes and are visible only to the thread which implements
it. Otherwise, critical section just refers to the area of code protected
by a mutex*]

In short, could you please help with the simplest possible mutex **example
program** and the simplest possible **explanation** on the logic of how it
works? I'm sure this will help **plenty** of other newbies.

*Here goes my humble attempt to explain the concept to newbies around the
world: (a [color coded version](http://nrecursions.blogspot.com/2014/08/mutex-tutorial-and-example.html)
on my blog too)*

A lot of people run to a lone phone booth (they don't have mobile phones)
to talk to their loved ones. The first person to catch the door-handle of
the booth, is the one who is allowed to use the phone. He has to keep holding
on to the handle of the door as long as he uses the phone, otherwise someone
else will catch hold of the handle, throw him out and talk to his wife :)
There's no queue system as such. When the person finishes his call, comes
out of the booth and leaves the door handle, the next person to get hold
of the door handle will be allowed to use the phone.

A **thread** is : Each person

The **mutex** is : The door handle

The **lock** is : The person's hand

The **resource** is : The phone

Any thread which has to execute some lines of code which should not be modified
by other threads at the same time (using the phone to talk to his wife),
has to first acquire a lock on a mutex (clutching the door handle of the
booth). Only then will a thread be able to run those lines of code (making
the phone call).

Once the thread has executed that code, it should release the lock on the
mutex so that another thread can acquire a lock on the mutex (other people
being able to access the phone booth).

[*The concept of having a mutex is a bit absurd when considering real-world
exclusive access, but in the programming world I guess there was no other
way to let the other threads 'see' that a thread was already executing some
lines of code. There are concepts of recursive mutexes etc, but this example
was only meant to show you the basic concept. Hope the example gives you
a clear picture of the concept.*]

**With C++11 threading:**

```C++
#include <iostream>
#include <thread>
#include <mutex>

std::mutex m;//you can use std::lock_guard if you want to be exception safe
int i = 0;

void makeACallFromPhoneBooth() 
{
    m.lock();//man gets a hold of the phone booth door and locks it. The other men wait outside
      //man happily talks to his wife from now....
      std::cout << i << " Hello Wife" << std::endl;
      i++;//no other thread can access variable i until m.unlock() is called
      //...until now, with no interruption from other men
    m.unlock();//man lets go of the door handle and unlocks the door
}

int main() 
{
    //This is the main crowd of people uninterested in making a phone call

    //man1 leaves the crowd to go to the phone booth
    std::thread man1(makeACallFromPhoneBooth);
    //Although man2 appears to start second, there's a good chance he might
    //reach the phone booth before man1
    std::thread man2(makeACallFromPhoneBooth);
    //And hey, man3 also joined the race to the booth
    std::thread man3(makeACallFromPhoneBooth);

    man1.join();//man1 finished his phone call and joins the crowd
    man2.join();//man2 finished his phone call and joins the crowd
    man3.join();//man3 finished his phone call and joins the crowd
    return 0;
}
```

Compile and run using

```bash
g++ -std=c++0x -pthread -o thread thread.cpp; ./thread
```

Instead of explicitly using `lock` and `unlock`, you can use brackets [as
shown here](https://software.intel.com/en-us/node/527509), if you are using
a scoped lock [for the advantage it provides](https://stackoverflow.com/questions/15179553/boost-scoped-lock-vs-plain-lock-unlock).
Scoped locks have a slight performance overhead though.

For those looking for the shortex mutex example:

```C++
#include <mutex>

int main() {
    std::mutex m;

    m.lock();
    // do thread-safe stuff
    m.unlock();
}
```
