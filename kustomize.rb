class Kustomize < Formula
  desc "Template-free customization of Kubernetes YAML manifests"
  homepage "https://github.com/kubernetes-sigs/kustomize"
  url "https://github.com/kubernetes-sigs/kustomize.git",
      :tag      => "v1.0.11",
      :revision => "8f701a00417a812558a7b785e8354957afa469ae"

  bottle do
    sha256 cellar: :any, catalina:    "17605f1674a5bc1f374f13137db550c51181e7eebae59513444d0f46032a2a78"
    sha256 cellar: :any, mojave:      "ead278adf991ed6056b97806f5a7815f76340492d00b39801c863e907826a2ec"
    sha256 cellar: :any, high_sierra: "f2a1fcbee158d5478f786a1ff7667c65061e15f8a0ebecdbc69e748c184cc8ef"
    sha256 cellar: :any, sierra:      "3b554722d5011a8aa1906046d4d65b3482a121baf36c737aca4de1d270171e42"
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
