# LGTM Stack with Tilt
# A complete observability stack in one command

load('ext://helm_resource', 'helm_resource', 'helm_repo')

# Configuration
config.define_string('domain', args=False, usage='Domain for ingress (default: home.lab)')
config.define_bool('enable-tls', args=False, usage='Enable TLS with root CA (default: true)')
config.define_bool('enable-dns', args=False, usage='Enable external-dns (default: false)')

cfg = config.parse()
DOMAIN = cfg.get('domain', 'home.lab')
ENABLE_TLS = cfg.get('enable-tls', True)
ENABLE_DNS = cfg.get('enable-dns', False)

# Allow running in any Kubernetes context
allow_k8s_contexts(k8s_context())

print("🚀 LGTM Stack Deployment")
print("   Domain: *.{dmn}".format(dmn=DOMAIN))
print("   TLS: {tls}".format(tls=ENABLE_TLS))
print("   External DNS: {dns}".format(dns=ENABLE_DNS))
print("")

# Helm repositories
helm_repo(
    name='prometheus-community',
    url='https://prometheus-community.github.io/helm-charts',
    labels=['helm-repo'],
)

helm_repo(
    name='grafana',
    url='https://grafana.github.io/helm-charts',
    labels=['helm-repo'],
)

helm_repo(
    name='jetstack',
    url='https://charts.jetstack.io',
    labels=['helm-repo'],
)

helm_repo(
    name='ingress-nginx-repo',
    url='https://kubernetes.github.io/ingress-nginx',
    labels=['helm-repo'],
)

# Cert-manager (for TLS)
if ENABLE_TLS:
    helm_resource(
        name='cert-manager',
        chart='jetstack/cert-manager',
        namespace='cert-manager',
        flags=[
            '--create-namespace',
            '--set', 'crds.enabled=true',
        ],
        resource_deps=['jetstack'],
        labels=['infra', 'cert-manager'],
    )
    
    k8s_yaml('./configs/root-ca.yaml')
    k8s_resource(
        objects=[
            'selfsigned-bootstrap:clusterissuer',
            'home-lab-root-ca:certificate',
            'home-lab-ca-issuer:clusterissuer',
        ],
        new_name='root-ca',
        resource_deps=['cert-manager'],
        labels=['cert-manager'],
    )
    
    k8s_yaml('./configs/wildcard-cert.yaml')
    k8s_resource(
        objects=['wildcard-home-lab:certificate'],
        new_name='wildcard-cert',
        resource_deps=['root-ca'],
        labels=['cert-manager'],
    )

# Ingress controller
helm_resource(
    name='ingress-nginx',
    chart='ingress-nginx-repo/ingress-nginx',
    namespace='ingress-nginx',
    flags=[
        '--create-namespace',
        '--set', 'controller.hostNetwork=true',
        '--set', 'controller.kind=DaemonSet',
    ],
    resource_deps=['ingress-nginx-repo'],
    labels=['infra', 'ingress'],
)

# External DNS (optional)
if ENABLE_DNS:
    k8s_yaml('./configs/external-dns.yaml')
    k8s_resource(
        workload='external-dns',
        new_name='external-dns',
        labels=['infra', 'dns'],
    )

# Prometheus Operator
helm_resource(
    name='prometheus-operator',
    chart='prometheus-community/kube-prometheus-stack',
    namespace='monitoring',
    flags=[
        '--create-namespace',
        '--set', 'grafana.enabled=false',  # We'll use LGTM's Grafana
    ],
    resource_deps=['prometheus-community'],
    labels=['monitoring', 'prometheus'],
)

# LGTM Stack
helm_resource(
    name='lgtm',
    chart='grafana/lgtm-distributed',
    namespace='monitoring',
    flags=[
        '--create-namespace',
        '--values', './configs/lgtm-values.yaml',
    ],
    resource_deps=['grafana', 'prometheus-operator'],
    labels=['monitoring', 'lgtm'],
)

# Ingress for Grafana
k8s_yaml('./configs/lgtm-ingress.yaml')
k8s_resource(
    objects=['grafana:ingress'],
    new_name='lgtm-ingress',
    resource_deps=['lgtm', 'ingress-nginx'] + (['wildcard-cert'] if ENABLE_TLS else []),
    labels=['monitoring', 'ingress'],
)

# Local resource: Export CA certificate
if ENABLE_TLS:
    local_resource(
        name='export-ca-cert',
        cmd='./scripts/export-ca.sh',
        resource_deps=['root-ca'],
        auto_init=False,
        trigger_mode=TRIGGER_MODE_MANUAL,
        labels=['utilities'],
    )

# Local resource: Verify stack health
local_resource(
    name='verify-stack',
    cmd='./scripts/verify-stack.sh',
    resource_deps=['lgtm'],
    auto_init=False,
    trigger_mode=TRIGGER_MODE_MANUAL,
    labels=['utilities'],
)

print("")
print("✅ Tiltfile loaded successfully!")
print("")
print("Next steps:")
print("  1. Watch deployment: http://localhost:10350")
print("  2. Access Grafana: https://grafana.{DOMAIN}")
if ENABLE_TLS:
    print("  3. Trust CA: tilt trigger export-ca-cert")
print("")
