class Qcachegrind < Formula
  desc "Visualize data generated by Cachegrind and Calltree"
  homepage "https://apps.kde.org/kcachegrind/"
  url "https://download.kde.org/stable/release-service/24.08.0/src/kcachegrind-24.08.0.tar.xz"
  sha256 "3378ee7e6722172044176ca1c0f07b850bb1cece9a1564ac48ecb4f3dbfa7170"
  license "GPL-2.0-or-later"
  head "https://invent.kde.org/sdk/kcachegrind.git", branch: "master"

  # We don't match versions like 19.07.80 or 19.07.90 where the patch number
  # is 80+ (beta) or 90+ (RC), as these aren't stable releases.
  livecheck do
    url "https://download.kde.org/stable/release-service/"
    regex(%r{href=.*?v?(\d+\.\d+\.(?:(?![89]\d)\d+)(?:\.\d+)*)/?["' >]}i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "9d360a28439b636591db5ef60a3b51c16d4ecc436f3b8bd001acf78457ccbb3f"
    sha256 cellar: :any,                 arm64_ventura:  "efe8af75757b975c212401bf1e083044cf663048aeaca31747a0c9a11040d46f"
    sha256 cellar: :any,                 arm64_monterey: "2eae8bf26313c1a7bf4d24d8069f523d83ace7c35cb17b8a894e6d49dbd11761"
    sha256 cellar: :any,                 sonoma:         "059719cbfa1488eeaeae99616e97949907397361ffb95691e41def8ac97f7512"
    sha256 cellar: :any,                 ventura:        "79d082356eab252de45ff8030eb50660e30ed8bac324b616a6f40af4a86bcc49"
    sha256 cellar: :any,                 monterey:       "a1e23a2d556c485596e6d681bda529e715aecb8a2ae5472a44fe387740693eb1"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "3bf8b487d6935295b6a68670dff7ab1233223b8b48542901de8a0443bb18a158"
  end

  depends_on "graphviz"
  depends_on "qt"

  fails_with gcc: "5"

  def install
    args = %w[-config release]
    if OS.mac?
      spec = (ENV.compiler == :clang) ? "macx-clang" : "macx-g++"
      args += %W[-spec #{spec}]
    end

    qt = Formula["qt"]
    system qt.opt_bin/"qmake", *args
    system "make"

    if OS.mac?
      prefix.install "qcachegrind/qcachegrind.app"
      bin.install_symlink prefix/"qcachegrind.app/Contents/MacOS/qcachegrind"
    else
      bin.install "qcachegrind/qcachegrind"
    end
  end
end
