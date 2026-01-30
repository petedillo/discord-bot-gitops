# Discord AI Bot GitOps

Kubernetes manifests for deploying the Discord AI Bot using ArgoCD.

## Structure

```
kubernetes/
├── base/                 # Base manifests
│   ├── deployment.yaml
│   ├── namespace.yaml
│   ├── secret.yaml
│   └── kustomization.yaml
└── overlays/
    ├── dev/              # Development environment
    ├── stage/            # Staging environment
    └── prod/             # Production environment
```

## Deployment

Managed by ArgoCD. See the homelab GitOps repo for ArgoCD application definitions.

## Secrets

Replace placeholder secrets with SealedSecrets for production use:

```bash
kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
```

## Image Tags

- `dev-latest` - Development builds
- `stage-latest` - Staging builds
- `prod-latest` - Production builds
