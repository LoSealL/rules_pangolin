// Pure 3D drawing demo: opens a Pangolin window and renders a rotating
// scene (ground grid, coordinate axes, coloured spiral point cloud and a
// spinning coloured cube) with no UI panel or input handling.
//
// Usage: plot3d [seconds]
//   seconds == 0 (default): run until the window is closed
//   seconds > 0: exit automatically afterwards (handy for smoke testing)
#include <chrono>
#include <cmath>
#include <cstdio>
#include <vector>

#include <pangolin/pangolin.h>

namespace {

struct ColouredPoint {
  float x, y, z;
  float r, g, b;
};

std::vector<ColouredPoint> MakeSpiral(int n = 400) {
  std::vector<ColouredPoint> pts;
  pts.reserve(n);
  for (int i = 0; i < n; ++i) {
    const float t = i / static_cast<float>(n - 1);
    const float a = 6.0f * 3.14159265f * t;
    pts.push_back({3.0f * t * std::cos(a), -1.5f + 3.0f * t,
                   3.0f * t * std::sin(a), 0.2f + 0.8f * t, 1.0f - t,
                   0.3f + 0.5f * t});
  }
  return pts;
}

void DrawGrid(float extent = 5.0f, float step = 1.0f) {
  glLineWidth(1.0f);
  glColor4f(0.35f, 0.38f, 0.42f, 1.0f);
  glBegin(GL_LINES);
  for (float v = -extent; v <= extent + 0.001f; v += step) {
    glVertex3f(v, 0.0f, -extent);
    glVertex3f(v, 0.0f, extent);
    glVertex3f(-extent, 0.0f, v);
    glVertex3f(extent, 0.0f, v);
  }
  glEnd();
}

}  // namespace

int main(int argc, char** argv) {
  const double run_seconds = argc > 1 ? std::atof(argv[1]) : 0.0;
  const int width = 1024;
  const int height = 768;

  pangolin::CreateWindowAndBind("pangolin plot3d", width, height);
  glEnable(GL_DEPTH_TEST);

  pangolin::OpenGlRenderState s_cam(
      pangolin::ProjectionMatrix(width, height, 420, 420, width / 2.0,
                                 height / 2.0, 0.1, 100),
      pangolin::ModelViewLookAt(4, 3, -4, 0, 0, 0, pangolin::AxisY));
  pangolin::View& d_cam =
      pangolin::CreateDisplay().SetBounds(0.0, 1.0, 0.0, 1.0,
                                          -width / static_cast<double>(height));

  const std::vector<ColouredPoint> spiral = MakeSpiral();
  const auto t0 = std::chrono::steady_clock::now();
  float angle = 0.0f;

  std::printf("plot3d: spinning up (close the window or pass a second limit)\n");
  while (!pangolin::ShouldQuit()) {
    if (run_seconds > 0.0 &&
        std::chrono::duration<double>(std::chrono::steady_clock::now() - t0)
                .count() >= run_seconds) {
      break;
    }

    glClearColor(0.08f, 0.09f, 0.12f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    d_cam.Activate(s_cam);

    DrawGrid();
    pangolin::glDrawAxis(2.0);

    // Spinning coloured cube hovering above the grid.
    angle = std::fmod(angle + 0.6f, 360.0f);
    glPushMatrix();
    glTranslatef(0.0f, 1.2f, 0.0f);
    glRotatef(angle, 0.0f, 1.0f, 0.0f);
    glScalef(0.8f, 0.8f, 0.8f);
    pangolin::glDrawColouredCube(-0.5f, 0.5f);
    glPopMatrix();

    // Colourful spiral of points.
    glPointSize(3.0f);
    glBegin(GL_POINTS);
    for (const ColouredPoint& p : spiral) {
      glColor4f(p.r, p.g, p.b, 1.0f);
      glVertex3f(p.x, p.y, p.z);
    }
    glEnd();

    pangolin::FinishFrame();
  }

  std::printf("plot3d: done\n");
  return 0;
}
