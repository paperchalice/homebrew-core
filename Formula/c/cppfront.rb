class Cppfront < Formula
  desc "C++ Syntax 2 -> Syntax 1 compiler"
  homepage "https://hsutter.github.io/cppfront/"
  url "https://github.com/hsutter/cppfront/archive/refs/tags/v0.7.2.tar.gz"
  sha256 "fb44c6a65fa19b185ddf385dd3bfea05afe0bc8260382b7a8e3c75b3c9004cd6"
  license "CC-BY-NC-ND-4.0"

  def install
    system ENV.cxx, "source/cppfront.cpp", "-std=c++20", "-o", "cppfront"
    bin.install "cppfront"
    prefix.install "include"
  end

  test do
    (testpath/"hello.cpp2").write <<~EOS
      main: () = std::cout << "Hello, world!" << std::endl;
    EOS
    system bin/"cppfront", "hello.cpp2"
    system ENV.cxx, "hello.cpp", "-std=c++20", "-I#{include}", "-o", "hello"
    assert_equal "Hello, world!\n", shell_output("./hello")
  end
end
