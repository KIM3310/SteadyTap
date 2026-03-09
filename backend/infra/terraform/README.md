# SteadyTap Backend Terraform

Minimal Cloud Run deployment skeleton for the SteadyTap backend.

## Apply

```bash
terraform init
terraform apply \
  -var="project_id=your-project" \
  -var="image=asia-northeast3-docker.pkg.dev/your-project/apps/steadytap-backend:latest"
```

Use `env` to inject `STEADYTAP_API_KEY`, `STEADYTAP_DB_PATH`, and `STEADYTAP_RUNTIME_STORE_PATH`.
