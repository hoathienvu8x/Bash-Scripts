#include <iostream>
#include <httplib.h>

using httplib::Client;
using httplib::Params;

int main(int argc, char **argv) {
    Client cli("127.0.0.1", 9600);
    
    Params params{
        { "question", "john" },
        { "note", "coder" }
    };
    
    auto res = cli.Post("/", params);
    if (res && res->status == 200) {
        std::cout << res->body << std::endl;
    }
    return 0;
}