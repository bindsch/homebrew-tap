class Codemux < Formula
  desc "Unified CLI for AI coding agents"
  homepage "https://github.com/bindsch/codemux"
  url "https://github.com/bindsch/codemux.git", tag: "v0.2.0", revision: "db3d09676a8003cf85787d3e06ac6ac3687c040a"
  license "MIT"

  head "https://github.com/bindsch/codemux.git", branch: "main"

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
      assert_equal "0.2.0", version_output
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
