#include <iostream>
#include <string>
#include <httplib.h>
#include <unistd.h>
#include <json.h>

using httplib::Server;
using httplib::Request;
using httplib::Response;
using jsonlib::JSON;

JSON *json_decode(std::string);
std::string json_encode(JSON);

int main(int argc, char **argv) {
    Server svr;
    svr.Get("/", [](const Request& req, Response& res) {
        JSON *data = json_decode("{'question':'',answer:'Hi there'}");
        if (data != NULL) {
            JSON resp = *data;
            if (req.has_param("question")) {
                resp["question"] = JSON(req.get_param_value("question")).as<std::string>();
            }
            res.set_content(json_encode(resp), "text/plain");
        } else {
            res.set_content("{}", "text/plain");
        }
    });
    svr.Post("/", [](const Request& req, Response& res) {
        JSON *data = json_decode("{'question':'',answer:'Hi there'}");
        if (data != NULL) {
            JSON resp = *data;
            if (req.has_param("question")) {
                resp["question"] = JSON(req.get_param_value("question")).as<std::string>();
            }
            res.set_content(json_encode(resp), "text/plain");
        } else {
            res.set_content("{}", "text/plain");
        }
    });
    svr.listen("127.0.0.1", 9600);
    return 0;
}

JSON *json_decode(std::string str) {
    return new JSON(str);
}
std::string json_encode(JSON src) {
    return src.as_str(false, true, false);
}