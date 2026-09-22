// Includes the umbrella header <pangolin/pangolin.h>, which pulls in every
// C++ component (display, opengl, windowing, video, plot, tools, ...), links
// the full library and exercises a graphics-free subset at runtime so the
// test also passes on headless machines (WSL without a running X server).
#include <iostream>

#include <pangolin/pangolin.h>

int main() {
  pangolin::Var<std::string> greeting("smoke.greeting", "hello pangolin");
  pangolin::ManagedImage<uint8_t> image(8, 6);
  image.Memset(0xAA);

  if (greeting.Get() != "hello pangolin" || image.w != 8 || image.h != 6 ||
      image(0, 0) != 0xAA) {
    std::cerr << "pangolin smoke test failed" << std::endl;
    return 1;
  }

  std::cout << "pangolin smoke ok: " << greeting.Get() << " "
            << image.w << "x" << image.h << std::endl;
  return 0;
}
