class Torchvision < Formula
  include Language::Python::Virtualenv

  desc "Datasets, transforms, and models for computer vision"
  homepage "https://github.com/pytorch/vision"
  url "https://github.com/pytorch/vision/archive/refs/tags/v0.17.0.tar.gz"
  sha256 "55e395d5c7d9bf7658c82ac633cac2224aa168e1bfe8bb5b2b2a296c792a3500"
  license "BSD-3-Clause"
  revision 9

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "449d5dd160c92d271153c7b527588ae5e3e33beecb756364ec26ec37191bd7c6"
    sha256 cellar: :any,                 arm64_ventura:  "9983c2fb5dab25a6e9cbd66a02393bffc432e023bdf6dbe6cf422fe3269f8f73"
    sha256 cellar: :any,                 arm64_monterey: "820d5713722a6970445c4d7a4a19faa4565b2b7645a45421d8d7ba354de2db48"
    sha256 cellar: :any,                 sonoma:         "face42044172ba04a3ee027e6099bc532320b9570d3ad52d16cb1a1e8ff25312"
    sha256 cellar: :any,                 ventura:        "35c7b04c76f74c4e904f32b841eff9ee78c504054f191285554f81e09b244db1"
    sha256 cellar: :any,                 monterey:       "93cc1bd9419c2d233f9dd5c209b221e0c23f4b332cbb84e93d1284910a5f9696"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "0b2bf4c303aa11e8c22c414d2c13f141bd69a90c116e487b0126a1827d4b068f"
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "python@3.12" => [:build, :test]
  depends_on "abseil"
  depends_on "certifi"
  depends_on "jpeg-turbo"
  depends_on "libpng"
  depends_on "numpy"
  depends_on "pillow"
  depends_on "protobuf"
  depends_on "pytorch"

  on_macos do
    depends_on "libomp"
  end

  resource "charset-normalizer" do
    url "https://files.pythonhosted.org/packages/63/09/c1bc53dab74b1816a00d8d030de5bf98f724c52c1635e07681d312f20be8/charset-normalizer-3.3.2.tar.gz"
    sha256 "f30c3cb33b24454a82faecaf01b19c18562b1e89558fb6c56de4d9118a032fd5"
  end

  resource "idna" do
    url "https://files.pythonhosted.org/packages/e8/ac/e349c5e6d4543326c6883ee9491e3921e0d07b55fdf3cce184b40d63e72a/idna-3.8.tar.gz"
    sha256 "d838c2c0ed6fced7693d5e8ab8e734d5f8fda53a039c0164afb0b82e771e3603"
  end

  resource "requests" do
    url "https://files.pythonhosted.org/packages/63/70/2bf7780ad2d390a8d301ad0b550f1581eadbd9a20f896afe06353c2a2913/requests-2.32.3.tar.gz"
    sha256 "55365417734eb18255590a9ff9eb97e9e1da868d4ccd6402399eaf68af20a760"
  end

  resource "urllib3" do
    url "https://files.pythonhosted.org/packages/43/6d/fa469ae21497ddc8bc93e5877702dca7cb8f911e337aca7452b5724f1bb6/urllib3-2.2.2.tar.gz"
    sha256 "dd505485549a7a552833da5e6063639d0d177c04f23bc3864e41e5dc5f612168"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    jpeg = Formula["jpeg-turbo"]
    inreplace "setup.py",
      "(jpeg_found, jpeg_conda, jpeg_include, jpeg_lib) = find_library(\"jpeglib\", vision_include)",
      "(jpeg_found, jpeg_conda, jpeg_include, jpeg_lib) = (True, False, \"#{jpeg.include}\", \"#{jpeg.lib}\")"

    python3 = "python3.12"
    venv = virtualenv_create(libexec, python3)
    venv.pip_install resources

    # We depend on pytorch, but that's a separate formula, so install a `.pth` file to link them.
    # This needs to happen _before_ we try to install torchvision.
    site_packages = Language::Python.site_packages(python3)
    pytorch = Formula["pytorch"].opt_libexec
    (libexec/site_packages/"homebrew-pytorch.pth").write pytorch/site_packages

    venv.pip_install_and_link(buildpath, build_isolation: false)

    pkgshare.install "examples"
  end

  test do
    # test that C++ libraries are available
    # See also https://github.com/pytorch/vision/issues/2134#issuecomment-1793846900
    (testpath/"test.cpp").write <<~EOS
      #include <assert.h>
      #include <torch/script.h>
      #include <torch/torch.h>
      #include <torchvision/vision.h>
      #include <torchvision/ops/nms.h>

      int main() {
        auto& ops = torch::jit::getAllOperatorsFor(torch::jit::Symbol::fromQualString("torchvision::nms"));
        assert(ops.size() == 1);
      }
    EOS
    pytorch = Formula["pytorch"]
    openmp_flags = if OS.mac?
      libomp = Formula["libomp"]
      %W[
        -Xpreprocessor -fopenmp
        -I#{libomp.opt_include}
        -L#{libomp.opt_lib} -lomp
      ]
    else
      %w[-fopenmp]
    end
    system ENV.cxx, "-std=c++17", "test.cpp", "-o", "test", *openmp_flags,
                    "-I#{pytorch.opt_include}",
                    "-I#{pytorch.opt_include}/torch/csrc/api/include",
                    "-L#{pytorch.opt_lib}", "-ltorch", "-ltorch_cpu", "-lc10",
                    "-L#{lib}", *("-Wl,--no-as-needed" if OS.linux?), "-ltorchvision"

    system "./test"

    # test that the `torchvision` Python module is available
    cp test_fixtures("test.png"), "test.png"
    system libexec/"bin/python", "-c", <<~EOS
      import torch
      import torchvision
      t = torchvision.io.read_image("test.png")
      assert isinstance(t, torch.Tensor)
    EOS
  end
end
