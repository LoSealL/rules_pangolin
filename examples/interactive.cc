// Interactive demo: pangolin control panel (sliders / toggles), mouse-orbit
// camera via Handler3D and click-to-place points.
//
// Usage: interactive [seconds]   (0 = run until closed, see plot3d.cc)
//
// Controls:
//   - mouse drag      orbit the 3D camera
//   - mouse wheel     zoom
//   - left click      drop a point at the clicked world position
//   - 'c'             clear all dropped points
//   - space           toggle the spin animation (panel toggle too)
#include <chrono>
#include <cmath>
#include <cstdio>
#include <vector>

#include <pangolin/pangolin.h>

// Handler3D already computes the world-space position of every click;
// a subclass just has to record it (see HandlerBase3D::Selected_P_w).
class ClickHandler : public pangolin::Handler3D {
 public:
  using pangolin::Handler3D::Handler3D;

  void Mouse(pangolin::View& view, pangolin::MouseButton button, int x, int y,
             bool pressed, int button_state) override {
    pangolin::Handler3D::Mouse(view, button, x, y, pressed, button_state);
    if (pressed && button == pangolin::MouseButtonLeft) {
      points.push_back(Selected_P_w().cast<float>());
    }
  }

  std::vector<Eigen::Vector3f> points;
};

// hue in [0, 360) -> rgb, all components in [0, 1].
void HueToRgb(float hue, float* r, float* g, float* b) {
  const float c = 60.0f;
  const float h = std::fmod(std::fmod(hue, 360.0f) + 360.0f, 360.0f) / c;
  const float x = 1.0f - std::fabs(std::fmod(h, 2.0f) - 1.0f);
  const int i = static_cast<int>(h) % 6;
  float rgb[6][3] = {{1, x, 0}, {x, 1, 0}, {0, 1, x}, {0, x, 1}, {x, 0, 1}, {1, 0, x}};
  *r = rgb[i][0];
  *g = rgb[i][1];
  *b = rgb[i][2];
}

int main(int argc, char** argv) {
  const double run_seconds = argc > 1 ? std::atof(argv[1]) : 0.0;
  const int width = 1024;
  const int height = 768;

  pangolin::CreateWindowAndBind("pangolin interactive", width, height);
  glEnable(GL_DEPTH_TEST);

  pangolin::OpenGlRenderState s_cam(
      pangolin::ProjectionMatrix(width, height, 420, 420, width / 2.0,
                                 height / 2.0, 0.1, 100),
      pangolin::ModelViewLookAt(3, 2.5, -3, 0, 0.5, 0, pangolin::AxisY));

  ClickHandler handler(s_cam);

  pangolin::CreatePanel("ui")
      .SetBounds(0.0, 1.0, 0.0, pangolin::Attach::Pix(180));
  pangolin::View& d_cam =
      pangolin::CreateDisplay()
          .SetBounds(0.0, 1.0, pangolin::Attach::Pix(180), 1.0,
                     -width / static_cast<double>(height))
          .SetHandler(&handler);

  pangolin::Var<double> hue("ui.point hue", 200.0, 0.0, 360.0);
  pangolin::Var<double> point_size("ui.point size", 5.0, 1.0, 15.0);
  pangolin::Var<bool> spin("ui.spin", true, /*toggle=*/true);
  pangolin::Var<int> point_count("ui.points placed", 0);

  pangolin::RegisterKeyPressCallback(' ', [&spin]() { spin = !spin; });
  pangolin::RegisterKeyPressCallback(
      'c', [&handler, &point_count]() {
        handler.points.clear();
        point_count = 0;
      });

  const auto t0 = std::chrono::steady_clock::now();
  float angle = 0.0f;

  std::printf("interactive: left click places points, 'c' clears, space toggles spin\n");
  while (!pangolin::ShouldQuit()) {
    if (run_seconds > 0.0 &&
        std::chrono::duration<double>(std::chrono::steady_clock::now() - t0)
                .count() >= run_seconds) {
      break;
    }

    glClearColor(0.08f, 0.09f, 0.12f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    d_cam.Activate(s_cam);

    pangolin::glDrawAxis(1.0);

    // Reference cube at the origin.
    if (spin) {
      angle = std::fmod(angle + 0.4f, 360.0f);
    }
    glPushMatrix();
    glRotatef(angle, 0.0f, 1.0f, 0.0f);
    glScalef(0.5f, 0.5f, 0.5f);
    glTranslatef(0.0f, 1.0f, 0.0f);
    pangolin::glDrawColouredCube(-0.5f, 0.5f);
    glPopMatrix();

    // The points the user placed, coloured by the hue slider.
    float r, g, b;
    HueToRgb(static_cast<float>(hue.Get()), &r, &g, &b);
    glColor4f(r, g, b, 1.0f);
    glPointSize(static_cast<GLfloat>(point_size.Get()));
    glBegin(GL_POINTS);
    for (const Eigen::Vector3f& p : handler.points) {
      glVertex3f(p.x(), p.y(), p.z());
    }
    glEnd();

    point_count = static_cast<int>(handler.points.size());
    pangolin::FinishFrame();
  }

  std::printf("interactive: done\n");
  return 0;
}
