class Micromamba < Formula
  desc "Fast Cross-Platform Package Manager"
  homepage "https://github.com/mamba-org/mamba"
  license "BSD-3-Clause"
  head "https://github.com/mamba-org/mamba.git", branch: "main"

  stable do
    url "https://github.com/mamba-org/mamba/archive/refs/tags/micromamba-1.5.9.tar.gz"
    sha256 "9ac3fb39fffb9a57a7cc102e885cf49d9bac47ec6446c7d8c850f6fc87b26af6"

    # fmt 11 compatibility
    # https://github.com/mamba-org/mamba/commit/4fbd22a9c0e136cf59a4f73fe7c34019a4f86344
    # https://github.com/mamba-org/mamba/commit/d0d7eea49a9083c15aa73c58645abc93549f6ddd
    patch :DATA
  end

  livecheck do
    url :stable
    strategy :github_latest do |json, regex|
      json["name"]&.scan(regex)&.map { |match| match[0] }
    end
  end

  bottle do
    rebuild 1
    sha256 cellar: :any,                 arm64_sonoma:   "88b51ba79028340a5f81ce13ca35446895e29c7b8a4b2ed3442b3fcf95c69bd6"
    sha256 cellar: :any,                 arm64_ventura:  "1789a8f976fe30c27c052c62e81d7a6bec1cfca9a7b38ce26c27548535cc6b98"
    sha256 cellar: :any,                 arm64_monterey: "54cd8bafa37922abb9fec44eaec97c428d151bd5f79f9f88a0e024d320314957"
    sha256 cellar: :any,                 sonoma:         "767711d0140c57c0382b7c32d3be464fb135462988447d3091cb96793c96115c"
    sha256 cellar: :any,                 ventura:        "b29817db6aa5e8fee0d4ad73c21243b9d528577ea5cb02b1d14e34c8ebe70ff9"
    sha256 cellar: :any,                 monterey:       "09e134355626d38fb15c547208cf040f18a20dc2b031192e724335a0c477268f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "d26b77759ba7012952ee52ad0b02374042981ccb1f0abe0556fffab535c00a39"
  end

  depends_on "cli11" => :build
  depends_on "cmake" => :build
  depends_on "nlohmann-json" => :build
  depends_on "spdlog" => :build
  depends_on "tl-expected" => :build

  depends_on "fmt"
  depends_on "libarchive"
  depends_on "libsolv"
  depends_on "lz4"
  depends_on "openssl@3"
  depends_on "reproc"
  depends_on "xz"
  depends_on "yaml-cpp"
  depends_on "zstd"

  uses_from_macos "python" => :build
  uses_from_macos "bzip2"
  uses_from_macos "curl", since: :ventura # uses curl_url_strerror, available since curl 7.80.0
  uses_from_macos "krb5"
  uses_from_macos "zlib"

  def install
    args = %W[
      -DBUILD_LIBMAMBA=ON
      -DBUILD_SHARED=ON
      -DBUILD_MICROMAMBA=ON
      -DMICROMAMBA_LINKAGE=DYNAMIC
      -DCMAKE_INSTALL_RPATH=#{rpath}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def caveats
    <<~EOS
      Please run the following to setup your shell:
        #{opt_bin}/micromamba shell init -s <your-shell> -p ~/micromamba
      and restart your terminal.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/micromamba --version").strip

    python_version = "3.9.13"
    system bin/"micromamba", "create", "-n", "test", "python=#{python_version}", "-y", "-c", "conda-forge"
    assert_match "Python #{python_version}", shell_output("#{bin}/micromamba run -n test python --version").strip
  end
end

__END__
diff --git a/libmamba/include/mamba/core/mamba_fs.hpp b/libmamba/include/mamba/core/mamba_fs.hpp
index 65c515c..0f158a8 100644
--- a/libmamba/include/mamba/core/mamba_fs.hpp
+++ b/libmamba/include/mamba/core/mamba_fs.hpp
@@ -1379,7 +1379,7 @@ struct fmt::formatter<::fs::u8path>
     }
 
     template <class FormatContext>
-    auto format(const ::fs::u8path& path, FormatContext& ctx)
+    auto format(const ::fs::u8path& path, FormatContext& ctx) const
     {
         return fmt::format_to(ctx.out(), "'{}'", path.string());
     }
diff --git a/libmamba/include/mamba/specs/version.hpp b/libmamba/include/mamba/specs/version.hpp
index 4272f18..cf69cd4 100644
--- a/libmamba/include/mamba/specs/version.hpp
+++ b/libmamba/include/mamba/specs/version.hpp
@@ -168,7 +168,7 @@ struct fmt::formatter<mamba::specs::VersionPartAtom>
     }
 
     template <class FormatContext>
-    auto format(const ::mamba::specs::VersionPartAtom atom, FormatContext& ctx)
+    auto format(const ::mamba::specs::VersionPartAtom atom, FormatContext& ctx) const
     {
         return fmt::format_to(ctx.out(), "{}{}", atom.numeral(), atom.literal());
     }
@@ -188,7 +188,7 @@ struct fmt::formatter<mamba::specs::Version>
     }
 
     template <class FormatContext>
-    auto format(const ::mamba::specs::Version v, FormatContext& ctx)
+    auto format(const ::mamba::specs::Version v, FormatContext& ctx) const
     {
         auto out = ctx.out();
         if (v.epoch() != 0)
diff --git a/libmamba/src/api/install.cpp b/libmamba/src/api/install.cpp
index c749b24..672ee29 100644
--- a/libmamba/src/api/install.cpp
+++ b/libmamba/src/api/install.cpp
@@ -9,6 +9,7 @@
 #include <fmt/color.h>
 #include <fmt/format.h>
 #include <fmt/ostream.h>
+#include <fmt/ranges.h>
 #include <reproc++/run.hpp>
 #include <reproc/reproc.h>
 
diff --git a/libmamba/src/core/context.cpp b/libmamba/src/core/context.cpp
index 5d1b65b..6068f75 100644
--- a/libmamba/src/core/context.cpp
+++ b/libmamba/src/core/context.cpp
@@ -8,6 +8,7 @@
 
 #include <fmt/format.h>
 #include <fmt/ostream.h>
+#include <fmt/ranges.h>
 #include <spdlog/pattern_formatter.h>
 #include <spdlog/sinks/stdout_color_sinks.h>
 #include <spdlog/spdlog.h>
diff --git a/libmamba/src/core/query.cpp b/libmamba/src/core/query.cpp
index d1ac04c..017522a 100644
--- a/libmamba/src/core/query.cpp
+++ b/libmamba/src/core/query.cpp
@@ -13,6 +13,7 @@
 #include <fmt/color.h>
 #include <fmt/format.h>
 #include <fmt/ostream.h>
+#include <fmt/ranges.h>
 #include <solv/evr.h>
 #include <spdlog/spdlog.h>
 
diff --git a/libmamba/src/core/run.cpp b/libmamba/src/core/run.cpp
index ec84ed5..5584cf5 100644
--- a/libmamba/src/core/run.cpp
+++ b/libmamba/src/core/run.cpp
@@ -15,6 +15,7 @@
 #include <fmt/color.h>
 #include <fmt/format.h>
 #include <fmt/ostream.h>
+#include <fmt/ranges.h>
 #include <nlohmann/json.hpp>
 #include <reproc++/run.hpp>
 #include <spdlog/spdlog.h>
diff --git a/libmamba/tests/src/doctest-printer/array.hpp b/libmamba/tests/src/doctest-printer/array.hpp
index 123ffff..6b54468 100644
--- a/libmamba/tests/src/doctest-printer/array.hpp
+++ b/libmamba/tests/src/doctest-printer/array.hpp
@@ -8,6 +8,7 @@
 
 #include <doctest/doctest.h>
 #include <fmt/format.h>
+#include <fmt/ranges.h>
 
 namespace doctest
 {
diff --git a/libmamba/tests/src/doctest-printer/vector.hpp b/libmamba/tests/src/doctest-printer/vector.hpp
index 0eb5cf0..b397f9e 100644
--- a/libmamba/tests/src/doctest-printer/vector.hpp
+++ b/libmamba/tests/src/doctest-printer/vector.hpp
@@ -8,6 +8,7 @@
 
 #include <doctest/doctest.h>
 #include <fmt/format.h>
+#include <fmt/ranges.h>
 
 namespace doctest
 {
diff --git a/micromamba/src/run.cpp b/micromamba/src/run.cpp
index c3af4ea..7c561af 100644
--- a/micromamba/src/run.cpp
+++ b/micromamba/src/run.cpp
@@ -10,6 +10,7 @@
 
 #include <fmt/color.h>
 #include <fmt/format.h>
+#include <fmt/ranges.h>
 #include <nlohmann/json.hpp>
 #include <reproc++/run.hpp>
 #include <spdlog/spdlog.h>
diff --git a/libmamba/src/core/package_info.cpp b/libmamba/src/core/package_info.cpp
index 00d80e8..8726d1c 100644
--- a/libmamba/src/core/package_info.cpp
+++ b/libmamba/src/core/package_info.cpp
@@ -11,6 +11,7 @@
 #include <tuple>
 
 #include <fmt/format.h>
+#include <fmt/ranges.h>
 
 #include "mamba/core/package_info.hpp"
 #include "mamba/specs/archive.hpp"
diff --git a/libmamba/tests/src/core/test_satisfiability_error.cpp b/libmamba/tests/src/core/test_satisfiability_error.cpp
index bb33724..081367b 100644
--- a/libmamba/tests/src/core/test_satisfiability_error.cpp
+++ b/libmamba/tests/src/core/test_satisfiability_error.cpp
@@ -11,6 +11,7 @@
 
 #include <doctest/doctest.h>
 #include <fmt/format.h>
+#include <fmt/ranges.h>
 #include <nlohmann/json.hpp>
 #include <solv/solver.h>
 
diff --git a/libmambapy/src/main.cpp b/libmambapy/src/main.cpp
index 94d38ce..0e82ad8 100644
--- a/libmambapy/src/main.cpp
+++ b/libmambapy/src/main.cpp
@@ -7,6 +7,7 @@
 #include <stdexcept>
 
 #include <fmt/format.h>
+#include <fmt/ranges.h>
 #include <nlohmann/json.hpp>
 #include <pybind11/functional.h>
 #include <pybind11/iostream.h>
