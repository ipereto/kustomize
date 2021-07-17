class Kustomize < Formula
  desc "Template-free customization of Kubernetes YAML manifests"
  homepage "https://github.com/kubernetes-sigs/kustomize"
  url "https://github.com/kubernetes-sigs/kustomize.git",
      :tag      => "v1.0.11",
      :revision => "8f701a00417a812558a7b785e8354957afa469ae"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "2aa6e8c3794c5040b9b9825eb20775edef89e9dbd241394fdfe436436dcebedd"
    sha256 cellar: :any_skip_relocation, big_sur:       "aa0f81c67ff35c6ab464eae0d7cbe2542f6c824d957ca9aa873288592d7f802d"
    sha256 cellar: :any_skip_relocation, catalina:      "3de9182e24c05af71c52f786069e4b1642e744c96c8084254114486ea1b09f40"
    sha256 cellar: :any_skip_relocation, mojave:        "301c04e466ebd878cb0c6ea11c275d936dc9ede8d8b9c167419bb6a3c62298f9"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "6eb394f9b9db714221367626c0d55928ed3ec4c7d91b04adfd0c8847e03f6a80"
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["CGO_ENABLED"] = "0"

    revision = Utils.popen_read("git", "rev-parse", "HEAD").strip
    tag = Utils.popen_read("git", "describe", "--tags").strip
    dir = buildpath/"src/sigs.k8s.io/kustomize"
    dir.install buildpath.children - [buildpath/".brew_home"]
    cd dir do
      ldflags = %W[
        -s -X sigs.k8s.io/kustomize/pkg/commands.kustomizeVersion=#{tag}
        -X sigs.k8s.io/kustomize/pkg/commands.gitCommit=#{revision}
      ]
      system "go", "install", "-ldflags", ldflags.join(" ")
      bin.install buildpath/"bin/kustomize"
      prefix.install_metafiles
    end
  end

  test do
    assert_match "KustomizeVersion:", shell_output("#{bin}/kustomize version")

    (testpath/"kustomization.yaml").write <<~EOS
      resources:
      - service.yaml
      patches:
      - patch.yaml
    EOS
    (testpath/"patch.yaml").write <<~EOS
      apiVersion: v1
      kind: Service
      metadata:
        name: brew-test
      spec:
        selector:
          app: foo
    EOS
    (testpath/"service.yaml").write <<~EOS
      apiVersion: v1
      kind: Service
      metadata:
        name: brew-test
      spec:
        type: LoadBalancer
    EOS
    output = shell_output("#{bin}/kustomize build #{testpath}")
    assert_match /type:\s+"?LoadBalancer"?/, output
  end
end
