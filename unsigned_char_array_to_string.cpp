/* https://gist.github.com/miguelmota/9837dc763da3bb507725251b40f6d863 */

#include <iostream>
#include <string>

int main(int argc, char **argv) {
  unsigned char mychar[len];
  std::string mytext(reinterpret_cast<char*>(mychar));
  print(mytext);
  return 0;
}
