CX = g++
CXX = gcc
LDFLAGS = -Wall -Werror -O3
CFLAGS = -std=c++11
INCDIR = $(shell pwd)/include
INCLUDES = -I./ -I/usr/local/include -I$(INCDIR) -lpthread -ldl
AOBJECTS = source/server.o
COBJECTS = source/client.o

server: $(AOBJECTS)
	$(CX) $(LDFLAGS) $(CFLAGS) $(AOBJECTS) -o server $(INCLUDES)

client:  $(COBJECTS)
	$(CX) $(LDFLAGS) $(CFLAGS) $(COBJECTS) -o client $(INCLUDES)

%.o: %.cpp
	$(CX) $(LDFLAGS) $(CFLAGS) -c $< $(INCLUDES) -o $@

clean:
	@rm -rf server client $(AOBJECTS) $(COBJECTS)
