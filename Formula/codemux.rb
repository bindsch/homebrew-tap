class Codemux < Formula
  desc "Unified CLI for AI coding agents"
  homepage "https://github.com/bindsch/codemux"
  url "https://github.com/bindsch/codemux.git", tag: "v2.0.0", revision: "7665a2e132c1909ffc042aa56300493e4411750c"
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
    # which would otherwise pick up an unrelated Bun installation. The
    # launcher carries the codemux_pinned_bun= assignment as the rewrite
    # target (exactly once; scripts/check-installed-layout.ts enforces it
    # and applies the same rewrite to its own copy). 2.0.0 removed the
    # literal `exec bun ` call the previous inreplace matched.
    inreplace libexec/"bin/codemux", "codemux_pinned_bun=", "codemux_pinned_bun=#{bun}"

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
