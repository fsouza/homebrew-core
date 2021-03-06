class Spack < Formula
  desc "Package manager that builds multiple versions and configurations of software"
  homepage "https://spack.io"
  url "https://github.com/spack/spack/archive/v0.16.2.tar.gz"
  sha256 "ed3e5d479732b0ba82489435b4e0f9088571604e789f7ab9bc5ce89030793350"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/spack/spack.git", branch: "develop"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "fcc821aadb5b5ec99c3d3e59609b5902bae2e7ab1925c62de9c23cb6f09da45a"
    sha256 cellar: :any_skip_relocation, big_sur:       "f15804975042d0283321011b5066461813cbc8944bcf0d71aaffbe28daf3d0f7"
    sha256 cellar: :any_skip_relocation, catalina:      "f15804975042d0283321011b5066461813cbc8944bcf0d71aaffbe28daf3d0f7"
    sha256 cellar: :any_skip_relocation, mojave:        "f15804975042d0283321011b5066461813cbc8944bcf0d71aaffbe28daf3d0f7"
  end

  depends_on "python@3.9"

  def install
    cp_r Dir["bin", "etc", "lib", "share", "var"], prefix.to_s
  end

  def post_install
    mkdir_p prefix/"var/spack/junit-report" unless (prefix/"var/spack/junit-report").exist?
  end

  test do
    system "#{bin}/spack", "--version"
    assert_match "zlib", shell_output("#{bin}/spack list zlib")

    # Set up configuration file and build paths
    %w[opt modules lmod stage test source misc cfg-store].each { |dir| (testpath/dir).mkpath }
    (testpath/"cfg-store/config.yaml").write <<~EOS
      config:
        install_tree: #{testpath}/opt
        module_roots:
          tcl: #{testpath}/modules
          lmod: #{testpath}/lmod
        build_stage:
          - #{testpath}/stage
        test_stage: #{testpath}/test
        source_cache: #{testpath}/source
        misc_cache: #{testpath}/misc
    EOS

    # spack install using the config file
    system "#{bin}/spack", "-C", "#{testpath}/cfg-store", "install", "--no-cache", "zlib"

    # Get the path to one of the compiled library files
    zlib_prefix = shell_output("#{bin}/spack -ddd -C #{testpath}/cfg-store find --format={prefix} zlib").strip
    zlib_dylib_file = Pathname.new "#{zlib_prefix}/lib/libz.dylib"
    assert_predicate zlib_dylib_file, :exist?
  end
end
