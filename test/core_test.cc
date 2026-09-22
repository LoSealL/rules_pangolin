// Exercises pango_core / pango_vars / pango_image without touching any
// windowing or OpenGL code, so it runs on headless machines (e.g. WSL).
#include <iostream>

#include <pangolin/image/managed_image.h>
#include <pangolin/utils/uri.h>
#include <pangolin/var/var.h>

int main() {
  // URI semantics follow upstream tests_uri.cpp: bracketed key=value pairs
  // are params; `url` holds everything after the params section.
  const pangolin::Uri uri = pangolin::ParseUri("metric:[w=640,h=480]//path/file.png");
  if (uri.scheme != "metric" || uri.url != "path/file.png" ||
      uri.full_uri != "metric:[w=640,h=480]//path/file.png" ||
      uri.Get<std::string>("w", "") != "640" || uri.Get<std::string>("h", "") != "480") {
    std::cerr << "uri parse failed" << std::endl;
    return 1;
  }

  pangolin::Var<int> answer("core.answer", 42);
  if (answer.Get() != 42) {
    std::cerr << "var init failed" << std::endl;
    return 1;
  }

  pangolin::ManagedImage<uint8_t> image(8, 6);
  image.Memset(0xAA);
  if (image.w != 8 || image.h != 6 || image(0, 0) != 0xAA || image(7, 5) != 0xAA) {
    std::cerr << "image failed" << std::endl;
    return 1;
  }

  std::cout << "pangolin core ok" << std::endl;
  return 0;
}
