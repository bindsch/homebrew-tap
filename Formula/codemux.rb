class Codemux < Formula
  desc "Unified CLI for AI coding agents"
  homepage "https://github.com/bindsch/codemux"
  url "https://github.com/bindsch/codemux.git", tag: "v0.4.0", revision: "03167239d7d4ba409f5a98b1db151137732544e2"
  license "MIT"

  head "https://github.com/bindsch/codemux.git", branch: "main"

  # Bottles are built on release and attached to a tap release of the same name.
  # A bottle also removes the network fetch that `bun install` performs when
  # building from source. Platforms without a bottle fall back to source.
  bottle do
    root_url "https://github.com/bindsch/homebrew-tap/releases/download/codemux-0.4.0"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "4fcd5f373c95b9b690033e52386f081cc80003332a8824e1b992648f9264a1dd"
  end

  depends_on "bindsch/tap/scode"
  depends_on "bun"

  def install
    bun = formula_opt_bin("bun")/"bun"

    libexec.install Dir["*"]

    # Runtime dependencies only; devDependencies are not needed to run the CLI.
    cd libexec do
      system bun, "install", "--frozen-lockfile", "--production", "--ignore-scripts"
    end

    # Pin the interpreter so the launcher does not depend on PATH ordering,
    # which would otherwise pick up an unrelated Bun installation.
    inreplace libexec/"bin/codemux", "exec bun ", "exec #{bun} "

    bin.install_symlink libexec/"bin/codemux"
  end

  test do
    version_output = shell_output("#{bin}/codemux --version").strip
    if build.head?
      assert_match(/^\d+\.\d+\.\d+$/, version_output)
    else
      # Derived from the tag in `url`, so a version bump needs no test edit.
      assert_equal version.to_s, version_output
    end

    # The launcher must resolve through the bin symlink to its package root.
    help = shell_output("#{bin}/codemux --help")
    assert_match "run", help
    assert_match "verify", help

    # Diagnostics run without any agent CLI installed.
    system bin/"codemux", "list"
    system bin/"codemux", "autonomy"
    system bin/"codemux", "verify"

    # The scode dependency satisfies the sandbox contract.
    assert_match "scode", shell_output("#{bin}/codemux verify --show-scode")
  end
end
