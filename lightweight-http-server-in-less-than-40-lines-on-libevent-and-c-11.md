## Lightweight HTTP Server in less than 40 Lines on libevent and C++11

Looking through programming articles sometimes I see posts about creating your own HTTP server. I am most interested in C++ so I often read blogs about it. After looking them through you could easily write you own web server "on sockets" using [boost.asio](http://www.boost.org/doc/libs/1_55_0/doc/html/boost_asio.html) or something else. I also examined libevent and libev. Each of them has its advantages. Libevent is of great interest to me for developing a small HTTP server. Considering some innovations in C++11 the code becomes much more space-efficient and allows for the creation of a basic HTTP server in less than 40 lines.

The information of this post will be useful for those not familiar with libevent and those who want to quickly create an HTTP server. There’s nothing innovative in this post, so you can use it as material for working in the right direction.

libevent is better than libev and boost.asio because of its embedded HTTP server and some abstraction for operating with buffers. It also has a large set of helper functions. You can examine HTTP protocol by yourself by writing a simple FSN (finite state machine) or maybe through some other means. When working with libevent – it’s all there already. You can also go to a lower level and write your own parser for HTTP and perform the work with sockets on libevent. I liked the detail level of this library. If you want to do something quickly you’ll find a higher-level interface that is usually less flexible. When there are more serious requirements you can go down gradually, level by level. The library allows doing many things, such as: asynchronous input/output, work with the network, work with timers, rpc, etc. You can also use it to create both server-side and client-side software.

### What for?

Creating a private small HTTP server can be dictated by certain needs, wish or unwillingness to use full-blown ready servers by one or other reason.

Suppose, you have some server software that operates according to some protocol and solves some tasks. You need to give some API for the given software according to an HTTP protocol. There are just several small functions possible for the server setup and getting its current state according to the HTTP protocol. For example, you can arrange them for GET requests processing with parameters returning a small xml/json/text response. In this case you’ll be able to easily create your own HTTP server that will provide the interface for your server software. If you also want to create a small private special service for the distribution of some file set or even create your own web application you can also use this small server for that purpose. You can use it for the construction of all-sufficient server software as well as for creation of auxiliary services within the limits of bigger systems.

### Lightweight HTTP Server in less than 40 Lines

You should perform the following steps in order to create a simple single-threaded HTTP server using libevent:

* Initialize a global object of the library using **event_init** function. You can use this function for single-threaded processing only. In order to execute a multi-threaded operation you should create a separate object for every thread.
* Create http server using **evhttp_start** in case of a single-threaded server with a global object of event processing. You should delete the object created with the help of **evhttp_start** by using **evhttp_free**.
* In order to respond to the incoming requests you should setup a callback function with the help of **evhttp_set_gencb**.
* Then you can start the loop of event processing using **event_dispatch** function. This function is meant for operating with the global object in one thread.
* When processing the request you can get a response buffer utilizing **evhttp_request_get_output_buffer** function. You can add some content to the buffer. For example, in order to send the line you can use **evbuffer_add_printf** function. If you want to send a file use **evbuffer_add_file** function. Then a response to the request should be sent. You can do this with the help of **evhttp_send_reply**.

*The code of a single-threaded server in less than 40 lines:*

```c++
#include <memory>
#include <cstdint>
#include <iostream>
#include <evhttp.h>
int main()
{
  if (!event_init())
  {
    std::cerr << "Failed to init libevent." << std::endl;
    return -1;
  }
  char const SrvAddress[] = "127.0.0.1";
  std::uint16_t SrvPort = 5555;
  std::unique_ptr<evhttp, decltype(&evhttp_free)> Server(evhttp_start(SrvAddress, SrvPort), &evhttp_free);
  if (!Server)
  {
    std::cerr << "Failed to init http server." << std::endl;
    return -1;
  }
  void (*OnReq)(evhttp_request *req, void *) = [] (evhttp_request *req, void *)
  {
    auto *OutBuf = evhttp_request_get_output_buffer(req);
    if (!OutBuf)
      return;
    evbuffer_add_printf(OutBuf, "<html><body><center><h1>Hello World!</h1></center></body></html>");
    evhttp_send_reply(req, HTTP_OK, "", OutBuf);
  };
  evhttp_set_gencb(Server.get(), OnReq, nullptr);
  if (event_dispatch() == -1)
  {
    std::cerr << "Failed to run messahe loop." << std::endl;
    return -1;
  }
  return 0;
}
```

We’ve got less than 40 lines that can process HTTP requests displaying "Hello World" line in response. We can also send files after replacing **evbuffer_add_printf** function by **evbuffer_add_file**. Such server can be called a base model. No auto dealer wants to sell the autos in their base model. They always want to sell additional options. But does the consumer need them and, if yes, how many?

Using ab utility for [*nix](https://kukuruku.co/hub/nix/) systems we can check the things such base model can provide us with.

```bash
$ ab -c 1000 -k -r -t 10 http://127.0.0.1:5555/
Server Software: 
Server Hostname: 127.0.0.1
Server Port: 5555
Document Path: /
Document Length: 64 bytes
Concurrency Level: 1000
Time taken for tests: 2.289 seconds
Complete requests: 50000
Failed requests: 0
Write errors: 0
Keep-Alive requests: 50000
Total transferred: 8500000 bytes
HTML transferred: 3200000 bytes
Requests per second: 21843.76 [#/sec] (mean)
Time per request: 45.780 [ms] (mean)
Time per request: 0.046 [ms] (mean, across all concurrent requests)
Transfer rate: 3626.41 [Kbytes/sec] received
Connection Times (ms)
min mean[±sd] median max
Connect: 0 3 48.6 0 1001
Processing: 17 42 9.0 43 93
Waiting: 17 42 9.0 43 93
Total: 19 45 49.7 43 1053
```

```bash
$ ab -c 1000 -r -t 10 http://127.0.0.1:5555/
Server Software: 
Server Hostname: 127.0.0.1
Server Port: 5555
Document Path: /
Document Length: 64 bytes
Concurrency Level: 1000
Time taken for tests: 5.004 seconds
Complete requests: 50000
Failed requests: 0
Write errors: 0
Total transferred: 6300000 bytes
HTML transferred: 3200000 bytes
Requests per second: 9992.34 [#/sec] (mean)
Time per request: 100.077 [ms] (mean)
Time per request: 0.100 [ms] (mean, across all concurrent requests)
Transfer rate: 1229.53 [Kbytes/sec] received
Connection Times (ms)
min mean[±sd] median max
Connect: 0 61 214.1 20 3028
Processing: 7 34 17.6 31 277
Waiting: 6 28 16.9 25 267
Total: 17 95 219.5 50 3055
```

The test has been run on a bit outdated laptop (2 kernels, 4 GB of main storage) controlled by 32-bit Ubuntu 12.10 operational system.

### Multithreaded HTTP Server

Is multithreading necessary? It’s a rhetorical question. We can arrange all IO in one thread, place requests into the queue and sort it out in several threads. In this case you can just add a queue and a pool of processing threads to the above mentioned server. But if you really want or need to build a multithreaded server it will be a bit longer than the previous one. You can implement RAII using C++11 with its smart pointers. I showed it with std::unique_ptr in the example above. Lambda functions also shorten the code a bit.

The example of a multithreaded server is similar to the single-threaded one in its ideology. Some peculiarities of multithreading can increase the server up to two times in the code size. More than 80 lines aren’t that much for a multithreaded HTTP server on C++.

One of solutions to be made:

* Create several threads. Their number should be equal to the doubled quantity of CPU cores. C++11 supports operation with threads so you don’t need to write your wrappers.
* Create an object operating with events using event_base_new function for each thread. event_base_free function should delete this object in the end. std::unique_ptr and RAII allow executing it more compactly.
* Create a separate HTTP server object for every thread using evhttp_new considering the created above object. You should delete this object as well using evhttp_free.
* Setup request handler with the help of evhttp_set_gencb.
* This step may seem the strangest one. You should create a socket and attach it to the network interface for several handlers. Each of the handlers is located in its thread. In order to operate with sockets (create a socket, adjust it, attach to the certain interface) you can utilize API. Then you pass the socket for the server operation using evhttp_accept_socket function. It’s too long. Libevent provides several functions to help to solve it. As I’ve mentioned before, libevent allows going to lower levels allowing users more finer grained control in cases of necessity. In this case evhttp_bind_socket_with_handle executes all of the first thread work on creating the socket, adjusting and attaching it. evhttp_bound_socket_get_fd extracts a socket for other threads from the adjusted object. All other threads are already using the socket having set it up to be processed by evhttp_accept_socket function. It’s a bit strange, but far easier than using sockets API. It’s even easier taking the cross-platforms into account. The API for Berkeley sockets may seem the same. But if you have written cross-platform software using it for Windows and Linux, you should know that the code written for one system differs from the code written for the other one.
* Start the event service loop. You should do it differently, in contrast to a single-threaded server as there are different objects. There’s event_base_dispatch function in libevent for that purpose. To my mind, it has one drawback: it’s difficult to correct it properly (for example, there should be a situation when you can call event_base_loopexit). In or case you can use event_base_loop function. It’s non-blocking even if there are no events to be processed. It returns control that allows you to terminate the event service loop and do something between the calls. There’s also a drawback as you should place a bit delay not to load the idling processor (in C++11 you can do it using std::this_thread::sleep_for(std::chrono::milliseconds(10)) ).
* Requests processing is similar to the first example.
* During another thread creation and adjustment there can be something wrong with its function. For example, some libevent function has thrown an error. You can throw an exception and catch it. Then you can send it out of the thread limits using C++11 facilities (std::exception_ptr, std::current_exception and std::rethrow_exception)

The code of a simple multithreaded server:
```c++
#include <stdexcept>
#include <iostream>
#include <memory>
#include <chrono>
#include <thread>
#include <cstdint>
#include <vector>
#include <evhttp.h>
int main()
{
  char const SrvAddress[] = "127.0.0.1";
  std::uint16_t const SrvPort = 5555;
  int const SrvThreadCount = 4;
  try
  {
    void (*OnRequest)(evhttp_request *, void *) = [] (evhttp_request *req, void *)
    {
      auto *OutBuf = evhttp_request_get_output_buffer(req);
      if (!OutBuf)
        return;
      evbuffer_add_printf(OutBuf, "<html><body><center><h1>Hello World!</h1></center></body></html>");
      evhttp_send_reply(req, HTTP_OK, "", OutBuf);
    };
    std::exception_ptr InitExcept;
    bool volatile IsRun = true;
    evutil_socket_t Socket = -1;
    auto ThreadFunc = [&] ()
    {
      try
      {
        std::unique_ptr<event_base, decltype(&event_base_free)> EventBase(event_base_new(), &event_base_free);
        if (!EventBase)
          throw std::runtime_error("Failed to create new base_event.");
        std::unique_ptr<evhttp, decltype(&evhttp_free)> EvHttp(evhttp_new(EventBase.get()), &evhttp_free);
        if (!EvHttp)
          throw std::runtime_error("Failed to create new evhttp.");
          evhttp_set_gencb(EvHttp.get(), OnRequest, nullptr);
        if (Socket == -1)
        {
          auto *BoundSock = evhttp_bind_socket_with_handle(EvHttp.get(), SrvAddress, SrvPort);
          if (!BoundSock)
            throw std::runtime_error("Failed to bind server socket.");
          if ((Socket = evhttp_bound_socket_get_fd(BoundSock)) == -1)
            throw std::runtime_error("Failed to get server socket for next instance.");
        }
        else
        {
          if (evhttp_accept_socket(EvHttp.get(), Socket) == -1)
            throw std::runtime_error("Failed to bind server socket for new instance.");
        }
        for ( ; IsRun ; )
        {
          event_base_loop(EventBase.get(), EVLOOP_NONBLOCK);
          std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
      }
      catch (...)
      {
        InitExcept = std::current_exception();
      }
    };
    auto ThreadDeleter = [&] (std::thread *t) { IsRun = false; t->join(); delete t; };
    typedef std::unique_ptr<std::thread, decltype(ThreadDeleter)> ThreadPtr;
    typedef std::vector<ThreadPtr> ThreadPool;
    ThreadPool Threads;
    for (int i = 0 ; i < SrvThreadCount ; ++i)
    {
      ThreadPtr Thread(new std::thread(ThreadFunc), ThreadDeleter);
      std::this_thread::sleep_for(std::chrono::milliseconds(500));
      if (InitExcept != std::exception_ptr())
      {
        IsRun = false;
        std::rethrow_exception(InitExcept);
      }
      Threads.push_back(std::move(Thread));
    }
    std::cout << "Press Enter fot quit." << std::endl;
    std::cin.get();
    IsRun = false;
  }
  catch (std::exception const &e)
  {
    std::cerr << "Error: " << e.what() << std::endl;
  }
  return 0;
}
```

You might have noticed that every thread is created after some delay. It’s a small hack that will be fixed in the server output version. I’ll just say that if we don’t do it we’ll have to synchronize our threads to execute the “strange step” of creating and attaching the socket. Let’s leave this hack to simplify the process. Using lambda functions may be seen as an issue. Lambdas can be a good solution when using them as some predicate during the work with standard algorithms. You could also think about using them when writing even bigger code parts. In the provided above example I could bring everything to a regular function, pass all the necessary parameters and get a code in C++03 style. At the same time lambda shortened the code a bit. I think that we can use long lambdas when the code isn’t big. They wouldn’t have a bad influence on the code. Of course, if you don’t write main function in 700 lines.

Multithreaded server testing has been run using the same parameters as in the above mentioned example.

```bash
$ ab -c 1000 -k -r -t 10 http://127.0.0.1:5555/
Server Software: 
Server Hostname: 127.0.0.1
Server Port: 5555
Document Path: /
Document Length: 64 bytes
Concurrency Level: 1000
Time taken for tests: 1.576 seconds
Complete requests: 50000
Failed requests: 0
Write errors: 0
Keep-Alive requests: 50000
Total transferred: 8500000 bytes
HTML transferred: 3200000 bytes
Requests per second: 31717.96 [#/sec] (mean)
Time per request: 31.528 [ms] (mean)
Time per request: 0.032 [ms] (mean, across all concurrent requests)
Transfer rate: 5265.68 [Kbytes/sec] received
```

```bash
$ ab -c 1000 -r -t 10 http://127.0.0.1:5555/
Server Software: 
Server Hostname: 127.0.0.1
Server Port: 5555
Document Path: /
Document Length: 64 bytes
Concurrency Level: 1000
Time taken for tests: 3.685 seconds
Complete requests: 50000
Failed requests: 0
Write errors: 0
Total transferred: 6300000 bytes
HTML transferred: 3200000 bytes
Requests per second: 13568.41 [#/sec] (mean)
Time per request: 73.701 [ms] (mean)
Time per request: 0.074 [ms] (mean, across all concurrent requests)
Transfer rate: 1669.55 [Kbytes/sec] received
Connection Times (ms)
min mean[±sd] median max
Connect: 0 36 117.2 23 1033
Processing: 3 37 10.0 37 247
Waiting: 3 30 8.7 30 242
Total: 9 73 118.8 61 1089
```

### Final Version of the Server

We’ve provided the base version, there’s also a version with some options set. Now it’s time to create something more useful and functional with some improvements.

*The minimal http server:*

```c++
#include "http_server.h"
#include "http_headers.h"
#include "http_content_type.h"
#include <iostream>
int main()
{
  try
  {
    using namespace Network;
    HttpServer Srv("127.0.0.1", 5555, 4,
      [&] (IHttpRequestPtr req)
      {
        req->SetResponseAttr(Http::Response::Header::Server::Value, "MyTestServer");
        req->SetResponseAttr(Http::Response::Header::ContentType::Value,
                             Http::Content::Type::html::Value);
        req->SetResponseString("<html><body><center><h1>Hello Wotld!</h1></center></body></html>");
      });
    std::cout << "Press Enter for quit." << std::endl;
    std::cin.get();
  }
  catch (std::exception const &e)
  {
    std::cout << e.what() << std::endl;
  }
  return 0;
}
```

It’s quite a minimal code size for HTTP server on C++. Such simplicity of the client code of the server creation is possible due to longer implementation which is hidden in the suggested wrapper for libevent. But the implementation hasn’t really increased. Its fragments will be described below.

Creating the server:

* Create a server of HttpServer type. The least parameters are: address and port the server will operate on, number of threads and the function to process requests (we can use a small lambda instead of creating a separate function or even an entire handler class). After the object creation our server will operate as long as the object exists.
* The handler accepts a pointer to IHttpRequest interface. Implementation of the latter hides all the work with libevent buffer and respond sending. While its parameters allow us to receive data from the incoming request and form a response.

IHttpRequest Interface:

```c++
namespace Network
{
  DECLARE_RUNTIME_EXCEPTION(HttpRequest)
  struct IHttpRequest
  {
    enum class Type
    {
      HEAD, GET, PUT, POST
    };
    typedef std::unordered_map<std::string, std::string> RequestParams;
    virtual ~IHttpRequest() {}
    virtual Type GetRequestType() const = 0;
    virtual std::string const GetHeaderAttr(char const *attrName) const = 0;
    virtual std::size_t GetContentSize() const = 0;
    virtual void GetContent(void *buf, std::size_t len, bool remove) const = 0;
    virtual std::string const GetPath() const = 0;
    virtual RequestParams const GetParams() const = 0;
    virtual void SetResponseAttr(std::string const &name, std::string const &val) = 0;
    virtual void SetResponseCode(int code) = 0;
    virtual void SetResponseString(std::string const &str) = 0;
    virtual void SetResponseBuf(void const *data, std::size_t bytes) = 0;
    virtual void SetResponseFile(std::string const &fileName) = 0;
  };
  typedef std::shared_ptr<IHttpRequest> IHttpRequestPtr;
}
```

The given interface will let us get the type of incoming request, some attributes (headers), size of the request body and the request body itself(if available). It will also allow us to return a with attributes (headers), the code of request processing termination and the response body (there are some methods for passing a string, some buffer or a file as a response). Each method can generate an exception of HttpRequestException type.

If you take another look at the server you’ll see the following lines in the code of requests processing:

```c++
req->SetResponseAttr(Http::Response::Header::Server::Value, "MyTestServer");
req->SetResponseAttr(Http::Response::Header::ContentType::Value,
                     Http::Content::Type::html::Value);
```

It’s building the response header. Such fields as “Content-Type” and “Server” are defined in the given example. Despite the fact that libevent has quite an extensive functional there’s no list of constants of header fields. There’s just an incomplete list of return codes that are often used. All constants are already defined in the suggested wrapper for libevent so that you wouldn’t have to bother about the lines defining header fields.

An Example of Defining String Constants

```c++
namespace Network
{
  namespace Http
  {
    namespace Request
    {
      namespace Header
      {
        DECLARE_STRING_CONSTANT(Accept, Accept)
        DECLARE_STRING_CONSTANT(AcceptCharset, Accept-Charset)
        // ...
      }
    }
    namespace Response
    {
      namespace Header
      {
        DECLARE_STRING_CONSTANT(AccessControlAllowOrigin, Access-Control-Allow-Origin)
        DECLARE_STRING_CONSTANT(AcceptRanges, Accept-Ranges)
        // ...
      }
    }
  }
}
```

We can define string constants as simple old style macros of pure C in header files. Or typifying them in C++ style, we could distribute their declaration and definition between .h and .cpp files. It’s possible to do without distributing them to files but make all typified definitions in C++ style in the header file only. We could use some approach with templates and write such macro (but heterogeneous solutions are more viable)

DECLARE_STRING_CONSTANT

```c++
#define DECLARE_STRING_CONSTANT(name_, value_) \
  namespace Private \
  { \
    template <typename T> \
    struct name_ \
    { \
      static char const Name[]; \
      static char const Value[]; \
    }; \
    template <typename T> \
    char const name_ <T>::Name[] = #name_; \
    template <typename T> \
    char const name_ <T>::Value[] = #value_; \
  } \
  typedef Private:: name_ <void> name_;
 ```
 
 Constants for assigning the content type are defined in almost the same way, but with some modification. I wanted to implement the search of content type by the filename extension so that it would be handy to send files as a response.

If you want to get something from the incoming request you can get the necessary information from its headers. For example, you want to know from what host and what page the transition to the resource has happened. You also want to know whether the user has cookies. You can get this information the following way:

```c++
std::string Host = req->GetHeaderAttr(Http::Request::Header::Host::Value);
std::string Referer = req->GetHeaderAttr(Http::Request::Header::Referer::Value);
std::string Cookie = req->GetHeaderAttr(Http::Request::Header::Cookie::Value);
```

You could also set some cookies for the user. With the help of cookies you can work with his session and track his activity (the example of working with response headers is provided in the server code).

It’s also easy to organize some API via HTTP. Suppose, we want to create methods to open a session, get some information about the server, close the session. The request lines to your server will look like the following:

```bash
http://myserver.com/service/login/OpenSession?user=nym&pwd=kakoyto
http://myserver.com/service/login/CliseSession?sessionId=nym1234567890
http://myserver.com/service/stat/GetInfo?sessionId=nym1234567890
```

The server can generate some response in xml format. It’s a task for the server developer. That’s how we should work with such requests and get some parameters from them:

```c++
auto Path = req->GetPath();
auto Params = req->GetParams();
```

One of the paths to the above mentioned example is /service/login/OpenSession, while parameters are a map of passed key/value pairs. The type of parameters map:

typedef std::unordered_map<std::string, std::string> RequestParams; After dealing with all the things we can implement using the final version of libevent wrapper we can look into the wrapper itself.

HttpServer Class

```c++
namespace Network
{
  DECLARE_RUNTIME_EXCEPTION(HttpServer)
  class HttpServer final
    : private Common::NonCopyable
  {
  public:
    typedef std::vector<IHttpRequest::Type> MethodPool;
    typedef std::function<void (IHttpRequestPtr)> OnRequestFunc;
    enum { MaxHeaderSize = static_cast<std::size_t>(-1), MaxBodySize = MaxHeaderSize };
    HttpServer(std::string const &address, std::uint16_t port,
               std::uint16_t threadCount, OnRequestFunc const &onRequest,
               MethodPool const &allowedMethods = {IHttpRequest::Type::GET },
               std::size_t maxHeadersSize = MaxHeaderSize,
               std::size_t maxBodySize = MaxBodySize);
  private:
    volatile bool IsRun = true;
    void (*ThreadDeleter)(std::thread *t) = [] (std::thread *t) { t->join(); delete t; };;
    typedef std::unique_ptr<std::thread, decltype(ThreadDeleter)> ThreadPtr;
    typedef std::vector<ThreadPtr> ThreadPool;
    ThreadPool Threads;
    Common::BoolFlagInvertor RunFlag;
  }; 
}
</source</spoiler>
<spoiler title="Реализация класса HttpServer"><source lang="cpp">
namespace Network
{
  HttpServer::HttpServer(std::string const &address, std::uint16_t port,
              std::uint16_t threadCount, OnRequestFunc const &onRequest,
              MethodPool const &allowedMethods,
              std::size_t maxHeadersSize, std::size_t maxBodySize)
    : RunFlag(&IsRun)
  {
    int AllowedMethods = -1;
    for (auto const i : allowedMethods)
      AllowedMethods |= HttpRequestTypeToAllowedMethod(i);
    bool volatile DoneInitThread = false;
    std::exception_ptr Except;
    evutil_socket_t Socket = -1;
    auto ThreadFunc = [&] ()
    {
      try
      {
        bool volatile ProcessRequest = false;
        RequestParams ReqPrm;
        ReqPrm.Func = onRequest;
        ReqPrm.Process = &ProcessRequest;
        typedef std::unique_ptr<event_base, decltype(&event_base_free)> EventBasePtr;
        EventBasePtr EventBase(event_base_new(), &event_base_free);
        if (!EventBase)
          throw HttpServerException("Failed to create new base_event.");
        typedef std::unique_ptr<evhttp, decltype(&evhttp_free)> EvHttpPtr;
        EvHttpPtr EvHttp(evhttp_new(EventBase.get()), &evhttp_free);
        if (!EvHttp)
          throw HttpServerException("Failed to create new evhttp.");
        evhttp_set_allowed_methods(EvHttp.get(), AllowedMethods);
        if (maxHeadersSize != MaxHeaderSize)
          evhttp_set_max_headers_size(EvHttp.get(), maxHeadersSize);
        if (maxBodySize != MaxBodySize)
          evhttp_set_max_body_size(EvHttp.get(), maxBodySize);
        evhttp_set_gencb(EvHttp.get(), &OnRawRequest, &ReqPrm);
        if (Socket == -1)
        {
          auto *BoundSock = evhttp_bind_socket_with_handle(EvHttp.get(), address.c_str(), port);
          if (!BoundSock)
            throw HttpServerException("Failed to bind server socket.");
          if ((Socket = evhttp_bound_socket_get_fd(BoundSock)) == -1)
            throw HttpServerException("Failed to get server socket for next instance.");
        }
        else
        {
          if (evhttp_accept_socket(EvHttp.get(), Socket) == -1)
            throw HttpServerException("Failed to bind server socket for new instance.");
        }
        DoneInitThread = true;
        for ( ; IsRun ; )
        {
          ProcessRequest = false;
          event_base_loop(EventBase.get(), EVLOOP_NONBLOCK);
          if (!ProcessRequest)
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }
      }
      catch (...)
      {
        Except = std::current_exception();
      }
    };
    ThreadPool NewThreads;
    for (int i = 0 ; i < threadCount ; ++i)
    {
      DoneInitThread = false;
      ThreadPtr Thread(new std::thread(ThreadFunc), ThreadDeleter);
      NewThreads.push_back(std::move(Thread));
      for ( ; ; )
      {
        if (Except != std::exception_ptr())
        {
          IsRun = false;
          std::rethrow_exception(Except);
        }
        if (DoneInitThread)
          break;
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
      }
    }
    Threads = std::move(NewThreads);
  }
}
```

You can look at the requests processing function in the full version by downloading the source code of examples. It has become a bit longer than in the examples provided above. I didn’t provide the IHttpRequest interface implementation as it isn’t really interesting due to its donkey work with libevent buffer. As for the rest, the code hasn’t changed much apart from some modifications and improvements.

The user server doesn’t have to process all types of HTTP requests. We can define a list of types to be processed by the server. There’s evhttp_set_allowed_methods in libevent for that purpose (wrapper defines GET type requests only by default). When we define the list of requests to be processed libevent will notify us when it’s impossible to execute such request. So we won’t have to perform additional checkups.

Intellectual curiosity can be aimed at creation and destruction. You can guard from the destructive curiosity (sending the server a huge header of http packet of forming a big request body) using evhttp_set_max_headers_size and evhttp_set_max_body_size functions. The provided methods will help to reduce emergency completions of the server.

Now I’ll provide a final version processing GET requests (it returns files from the specified directory). It also displays information about the host the request has been made from and the page used for turning to the resource processed by the server.

Final version of a simple and lightweight HTTP server

```c++
#include "http_server.h"
#include "http_headers.h"
#include "http_content_type.h"
#include <iostream>
#include <sstream>
#include <mutex>
int main()
{
  char const SrvAddress[] = "127.0.0.1";
  std::uint16_t SrvPort = 5555;
  std::uint16_t SrvThreadCount = 4;
  std::string const RootDir = "../test_content";
  std::string const DefaultPage = "index.html";
  std::mutex Mtx;
  try
  {
    using namespace Network;
    HttpServer Srv(SrvAddress, SrvPort, SrvThreadCount,
      [&] (IHttpRequestPtr req)
      {
        std::string Path = req->GetPath();
        Path = RootDir + Path + (Path == "/" ? DefaultPage : std::string());
        {
          std::stringstream Io;
          Io << "Path: " << Path << std::endl
             << Http::Request::Header::Host::Name << ": "
                  << req->GetHeaderAttr(Http::Request::Header::Host::Value) << std::endl
             << Http::Request::Header::Referer::Name << ": "
                  << req->GetHeaderAttr(Http::Request::Header::Referer::Value) << std::endl;
          std::lock_guard<std::mutex> Lock(Mtx);
          std::cout << Io.str() << std::endl;
        }
        req->SetResponseAttr(Http::Response::Header::Server::Value, "MyTestServer");
        req->SetResponseAttr(Http::Response::Header::ContentType::Value,
                             Http::Content::TypeFromFileName(Path));
        req->SetResponseFile(Path);
      });
    std::cin.get();
  }
  catch (std::exception const &e)
  {
    std::cout << e.what() << std::endl;
  }
  return 0;
}
```

### Summary

Besides the reviewed functionality, libevent contains a lot of other useful facilities. So there’re a lot of more things to be written and told about. This post showed the small part of it. I used the last example as a basis. I added some auxiliary functional to it and implemented a server where all sourcecode files of all the provided examples are located. There you can look at the server viability.

Now let’s test our server taking into account the network and location on the remote virtual server. Here’s the test result:

```bash
$ ab -c 1000 -k -r -t 10 http://t-boss.ru/libevent_test_http_srv.zip
Server Software: t-boss
Server Hostname: t-boss.ru
Server Port: 80
Document Path: /libevent_test_http_srv.zip
Document Length: 23756 bytes
Concurrency Level: 1000
Time taken for tests: 10.012 seconds
Complete requests: 2293
Failed requests: 0
Write errors: 0
Keep-Alive requests: 2293
Total transferred: 60628847 bytes
HTML transferred: 60328370 bytes
Requests per second: 229.02 [#/sec] (mean)
Time per request: 4366.365 [ms] (mean)
Time per request: 4.366 [ms] (mean, across all concurrent requests)
Transfer rate: 5913.65 [Kbytes/sec] received
```

More than two thousand requests have been processed in 10 seconds. In addition to the http server itself there are several other tasks: optimal logging arrangement, caching, etc. But they haven’t been implemented so we could experiment more with memcached, berkeley db and other technologies for creating a web application on C++ and write about results.

Thank you for your attention!
