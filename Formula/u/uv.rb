class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.4.7.tar.gz"
  sha256 "9a31cddc5338ae9eb39e6360c1d2f3610631debb0936dcaadf40d57678ab302a"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_sonoma:   "5c1707312ea0acc82cfbdfdbba4df75bafa52f63fe6e8c0dd345af100e996f19"
    sha256 cellar: :any_skip_relocation, arm64_ventura:  "92b0dab54931ac74139a86169d4db2f12e47250f4059fe381156bf3dd6d681d2"
    sha256 cellar: :any_skip_relocation, arm64_monterey: "7a6bfd06027db66c3a7c8cda71a5818029127fed6919276b1bee88331ae695b3"
    sha256 cellar: :any_skip_relocation, sonoma:         "47f1771baa23be1e76463d0e187170330b1696240d9c606747b3219a663fee8f"
    sha256 cellar: :any_skip_relocation, ventura:        "884f3967db4f85bba45deaec17cf6dea82b5bc28fc535728790ce22e4951bf9c"
    sha256 cellar: :any_skip_relocation, monterey:       "8239f7c9905b7a401b4bbb58d81326ea887c25ace47f04e799ba5a07994a999f"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "0dc79d3f44dcfd29daa276b6843ae3ea5af3a0c7191978011bb235cd8a336425"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build

  uses_from_macos "python" => :test
  uses_from_macos "xz"

  on_linux do
    # On macOS, bzip2-sys will use the bundled lib as it cannot find the system or brew lib.
    # We only ship bzip2.pc on Linux which bzip2-sys needs to find library.
    depends_on "bzip2"
  end

  def install
    ENV["UV_COMMIT_HASH"] = ENV["UV_COMMIT_SHORT_HASH"] = tap.user
    ENV["UV_COMMIT_DATE"] = time.strftime("%F")
    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    assert_match "ruff 0.5.1", shell_output("#{bin}/uvx -q ruff@0.5.1 --version")
  end
end
