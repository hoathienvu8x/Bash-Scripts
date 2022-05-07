---
title: C multithreaded chat client and server
link: https://codereview.stackexchange.com/questions/154969/c-multithreaded-chat-client-and-server
---

I've written a TCP chat application for the command line that supports multithreading.
I'm wondering whether I'm using best practices for socket programming, what
other types of functionality would be good to add.

The usage is `./chatserver port_number` and `./chatclient ip_address port_number`

**Client**

```C++
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>
#include <pthread.h>
#include <errno.h>

#define MESSAGE_BUFFER 500
#define USERNAME_BUFFER 10

typedef struct {
    char* prompt;
    int socket;
} thread_data;

// Connect to server
void * connect_to_server(int socket_fd, struct sockaddr_in *address) {
    int response = connect(socket_fd, (struct sockaddr *) address, sizeof *address);
    if (response < 0) {
        fprintf(stderr, "connect() failed: %s\n", strerror(errno));
        exit(1);
    } else {
      printf("Connected\n");
    }
}

// Get message from stdin and send to server
void * send_message(char prompt[USERNAME_BUFFER+4], int socket_fd, struct sockaddr_in *address) {
  printf("%s", prompt);
  char message[MESSAGE_BUFFER];
  char final_message[MESSAGE_BUFFER+USERNAME_BUFFER+1];
  while (fgets(message, MESSAGE_BUFFER, stdin) != NULL) {
      memset(final_message,0,strlen(final_message)); // Clear final message buffer
      strcat(final_message, prompt);
      strcat(final_message, message);
      printf("\n%s", prompt);
      if (strncmp(message, "/quit", 5) == 0) {
        printf("Closing connection...\n");
        exit(0);
      }
      send(socket_fd, final_message, strlen(final_message)+1, 0);
  }
}

void * receive(void * threadData) {
    int socket_fd, response;
    char message[MESSAGE_BUFFER];
    thread_data* pData = (thread_data*)threadData;
    socket_fd = pData->socket;
    char* prompt = pData->prompt;
    memset(message, 0, MESSAGE_BUFFER); // Clear message buffer

    // Print received message
    while(true) {
        response = recvfrom(socket_fd, message, MESSAGE_BUFFER, 0, NULL, NULL);
        if (response == -1) {
          fprintf(stderr, "recv() failed: %s\n", strerror(errno));
          break;
        } else if (response == 0) {
              printf("\nPeer disconnected\n");
              break;
        } else {
              printf("\nServer> %s", message);
              printf("%s", prompt);
              fflush(stdout); // Make sure "User>" gets printed
          }
    }
}

int main(int argc, char**argv) {
    long port = strtol(argv[2], NULL, 10);
    struct sockaddr_in address, cl_addr;
    char * server_address;
    int socket_fd, response;
    char prompt[USERNAME_BUFFER+4];
    char username[USERNAME_BUFFER];
    pthread_t thread;

    // Check for required arguments
    if (argc < 3) {
        printf("Usage: client ip_address port_number\n");
        exit(1);
    }

    // Get user handle
    printf("Enter your user name: ");
    fgets(username, USERNAME_BUFFER, stdin);
    username[strlen(username) - 1] = 0; // Remove newline char from end of string
    strcpy(prompt, username);
    strcat(prompt, "> ");

    server_address = argv[1];
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = inet_addr(server_address);
    address.sin_port = htons(port);
    socket_fd = socket(AF_INET, SOCK_STREAM, 0);

    connect_to_server(socket_fd, &address);

    // Create data struct for new thread
    thread_data data;
    data.prompt = prompt;
    data.socket = socket_fd;

    // Create new thread to receive messages
    pthread_create(&thread, NULL, receive, (void *) &data);

    // Send message
    send_message(prompt, socket_fd, &address);

    // Close socket and kill thread
    close(socket_fd);
    pthread_exit(NULL);
    return 0;
}
```

**Server**

```C++
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <pthread.h>

#define MESSAGE_BUFFER 500
#define CLIENT_ADDRESS_LENGTH 100

// Start server
void * start_server(int socket_fd, struct sockaddr_in *address) {
    bind(socket_fd, (struct sockaddr *) address, sizeof *address);
    printf("Waiting for connection...\n");
    listen(socket_fd, 10);
}

// Get message from stdin and send to client
void * send_message(int new_socket_fd, struct sockaddr *cl_addr) {
    char message[MESSAGE_BUFFER];
    while (fgets(message, MESSAGE_BUFFER, stdin) != NULL) {
        if (strncmp(message, "/quit", 5) == 0) {
            printf("Closing connection...\n");
            exit(0);
        }
        sendto(new_socket_fd, message, MESSAGE_BUFFER, 0, (struct sockaddr *) &cl_addr, sizeof cl_addr);
    }
}

void * receive(void * socket) {
    int socket_fd, response;
    char message[MESSAGE_BUFFER];
    memset(message, 0, MESSAGE_BUFFER); // Clear message buffer
    socket_fd = (int) socket;

    // Print received message
    while(true) {
        response = recvfrom(socket_fd, message, MESSAGE_BUFFER, 0, NULL, NULL);
        if (response) {
            printf("%s", message);
        }
    }
}

int main(int argc, char**argv) {
    long port = strtol(argv[1], NULL, 10);
    struct sockaddr_in address, cl_addr;
    int socket_fd, length, response, new_socket_fd;
    char client_address[CLIENT_ADDRESS_LENGTH];
    pthread_t thread;

    if (argc < 2) {
        printf("Usage: server port_number\n");
        exit(1);
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = port;
    socket_fd = socket(AF_INET, SOCK_STREAM, 0);

    start_server(socket_fd, &address);

    // Accept connection
    length = sizeof(cl_addr);
    new_socket_fd = accept(socket_fd, (struct sockaddr *) &cl_addr, &length);
    if (new_socket_fd < 0) {
        printf("Failed to connect\n");
        exit(1);
    }

    inet_ntop(AF_INET, &(cl_addr.sin_addr), client_address, CLIENT_ADDRESS_LENGTH);
    printf("Connected: %s\n", client_address);

    // Create new thread to receive messages
    pthread_create(&thread, NULL, receive, (void *) new_socket_fd);

    // Send message
    send_message(new_socket_fd, &cl_addr);

    // Close sockets and kill thread
    close(new_socket_fd);
    close(socket_fd);
    pthread_exit(NULL);
    return 0;
}
```

## Reviews

Regarding best practices, here are some suggestions for improvement:

1. Add code to initialize the error number variable, `errno`, to zero prior
to system calls that set this value.
2. Add code to check the return values of all calls providing return-value-error-indicators
against their documented error values and to deal with those errors including
inspecting the `errno` (if reported). I see that you do this in your client
code but less so in your server code.
3. Add code to provide human-readable information for system calls returning
their error indicators including the string describing the error number (provided
from strerror or the thread-safe version `strerror_r`). On dedicated server-side
code that may mean writing error information out to a log file or sending
it to a logging service (like via [`syslog`](https://linux.die.net/man/3/syslog)
to the system logger). On client-side code that may mean reporting the error
back to the user via standard error. I see that you do this in your client
code but less so in your server code.
4. For character-stream-based input (especially from a user), prefer the
use of the `getline()` function over `fgets()`.
5. Add code to deal with the partial sends of data that's possible with some
socket output calls like the `send()` and `sendto()` calls your code makes.
6. Tag the constants with the `const` keyword.
7. Ensure that the value in `port` will fit within the unsigned short integer
type of `address.sin_port`.
