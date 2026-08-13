class Usagemux < Formula
  desc "Provider-neutral subscription usage CLI"
  homepage "https://github.com/bindsch/usagemux"
  url "https://github.com/bindsch/usagemux.git", tag: "v0.1.0", revision: "c3ccf5fe7439491d6a44600d754f77ea9e38775f"
  license "MIT"

  head "https://github.com/bindsch/usagemux.git", branch: "main"

  bottle do
    root_url "https://github.com/bindsch/homebrew-tap/releases/download/usagemux-0.1.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "27beab83769d4263585c64f270cfe638a9d9a7bf1666360dab917f43b3c55474"
  end

  depends_on "bun"

  def install
    # No runtime dependencies, so the source tree is the whole install; the
    # launcher locates Bun itself from fixed prefixes rather than PATH.
    libexec.install Dir["*"]
    bin.install_symlink libexec/"bin/usagemux"
  end

  test do
    version_output = shell_output("#{bin}/usagemux --version").strip
    if build.head?
      assert_match(/^usagemux \d+\.\d+\.\d+$/, version_output)
    else
      # Derived from the tag in `url`, so a version bump needs no test edit.
      assert_equal "usagemux #{version}", version_output
    end

    # The launcher must resolve through the bin symlink to its package root.
    help = shell_output("#{bin}/usagemux --help")
    assert_match "snapshot", help

    # A snapshot must emit a complete, versioned document even when no provider
    # is configured: the per-client failure is reported inside `results`, not as
    # a non-zero exit or truncated JSON.
    snapshot = shell_output("#{bin}/usagemux snapshot --client claude --format json --timeout 5")
    parsed = JSON.parse(snapshot)
    assert_equal "1", parsed["schemaVersion"]
    assert_equal 1, parsed["results"].length
    assert_equal "claude", parsed["results"][0]["client"]
  end
end
