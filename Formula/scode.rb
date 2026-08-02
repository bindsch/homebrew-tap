class Scode < Formula
  desc "Safe sandbox wrapper for AI coding harnesses"
  homepage "https://github.com/bindsch/scode"
  url "https://github.com/bindsch/scode.git", tag: "v0.3.1", revision: "d1d9e0fd3a53dddeb9af37aff26da49bc181d4ee"
  license "MIT"

  head "https://github.com/bindsch/scode.git", branch: "main"

  # Bottles are built on release and attached to a tap release of the same name.
  # Platforms without a bottle fall back to building from source.
  bottle do
    root_url "https://github.com/bindsch/homebrew-tap/releases/download/scode-0.3.1"
    sha256 cellar: :any_skip_relocation, arm64_tahoe: "01845daab3ca80e5014ea1e669b20466068d300fcc182685b5d311be26324f81"
  end

  on_linux do
    depends_on "bubblewrap"
  end

  def install
    bin.install "scode"
    (lib/"scode").install "lib/no-sandbox.js"
    pkgshare.install "LICENSE"
    (pkgshare/"examples").install Dir["examples/*.yaml"]
  end

  test do
    # Version and file presence
    version_output = shell_output("#{bin}/scode --version").strip
    if build.head?
      assert_match(/^scode \d+\.\d+\.\d+$/, version_output)
    else
      # Derived from the tag in `url`, so a version bump needs no test edit.
      assert_equal "scode #{version}", version_output
    end
    assert_path_exists lib/"scode/no-sandbox.js"
    assert_path_exists pkgshare/"LICENSE"
    assert_path_exists pkgshare/"examples/sandbox.yaml"
    assert_path_exists pkgshare/"examples/sandbox-strict.yaml"
    assert_path_exists pkgshare/"examples/sandbox-paranoid.yaml"
    assert_path_exists pkgshare/"examples/sandbox-permissive.yaml"
    assert_path_exists pkgshare/"examples/sandbox-cloud-eng.yaml"
    assert_path_exists pkgshare/"examples/sandbox-grok.yaml"

    # Help output covers key flags and subcommands
    help = shell_output("#{bin}/scode --help")
    assert_match "--strict", help
    assert_match "--no-net", help
    assert_match "--trust", help
    assert_match "audit", help

    # Dry-run generates a sandbox profile without errors
    system bin/"scode", "--dry-run", "-C", testpath, "--", "true"

    # Strict + no-net dry-run
    system bin/"scode", "--dry-run", "--strict", "--no-net", "-C", testpath, "--", "true"

    # Audit subcommand parses denial patterns
    (testpath/"deny.log").write "deny(file-read-data) /tmp/brew-test-path\n"
    assert_match "/tmp/brew-test-path", shell_output("#{bin}/scode audit #{testpath}/deny.log")
  end
end
