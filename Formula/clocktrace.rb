class Clocktrace < Formula
  desc "Time tracker for your Mac and iPhone that you ask through your AI app"
  homepage "https://github.com/linhvu0711/clocktrace"
  url "https://github.com/linhvu0711/clocktrace/releases/download/v0.1.2/clocktrace-0.1.2-darwin-arm64.tar.gz"
  sha256 "84960b836ed2e71b2aa617a76b795b62dadc3f8761659694945990605741e36e"
  license "MIT"

  depends_on arch: :arm64
  depends_on macos: :golden_gate
  depends_on "node"

  def install
    # The tarball keeps the signed Clocktrace.app and the Helper in helper/,
    # next to node_modules, where the CLI finds them. setup copies the app
    # to ~/Applications whole.
    libexec.install Dir["*"]
    # Native modules ship prebuilds for every platform. Keep only this one.
    libexec.glob("node_modules/.pnpm/**/prebuilds/*").each do |path|
      rm_r(path) if path.basename(".node").to_s != "darwin-arm64"
    end
    (bin/"clocktrace").write_env_script libexec/"clocktrace",
                                        PATH: "#{formula_opt_bin("node")}:$PATH"
  end

  def caveats
    <<~EOS
      To start recording and connect your AI app, run:
        clocktrace setup
      Run it again after `brew upgrade`: the Collector and the AI app
      registrations point at the installed version of clocktrace and node.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/clocktrace --version")
    # The prebuild cleanup kept the native SQLite module for this Mac.
    (testpath/"sqlite.cjs").write <<~JS
      const { realpathSync } = require("node:fs");
      const core = realpathSync("#{libexec}/node_modules/@clocktrace/core");
      const Database = require(require.resolve("better-sqlite3", { paths: [core] }));
      console.log(new Database(":memory:").prepare("select 1 as n").get().n);
    JS
    assert_equal "1\n", shell_output("#{formula_opt_bin("node")}/node sqlite.cjs")
  end
end
