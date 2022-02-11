#include <iostream>
#include <string>
#include <exception>
#include <cstdlib>

int main(int argc, char *argv[]) {
    auto& file = std::cin;

    int n = 5;
    if (argc > 1) {
        try {
            n = std::stoi(argv[1]);
        } catch (std::exception& e) {
            std::cout << "Error: argument must be an int" << std::endl;
            std::exit(EXIT_FAILURE);
        }
    }

    file.seekg(0, file.end);

    n = n + 1; // Add one so the loop stops at the newline above
    while (file.tellg() != 0 && n) {
        file.seekg(-1, file.cur);
        if (file.peek() == '\n')
            n--;
    }

    if (file.peek() == '\n') // If we stop in the middle we will be at a newline
        file.seekg(1, file.cur);

    std::string line;
    while (std::getline(file, line))
        std::cout << line << std::endl;

    std::exit(EXIT_SUCCESS);
    return 0;
}
