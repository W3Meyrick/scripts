```hcl
terraform {
  required_version = ">= 1.8.0" # provider functions
  required_providers {
    vault = { source = "hashicorp/vault" }
    tls   = { source = "hashicorp/tls" }
    time  = { source = "hashicorp/time", version = ">= 0.11.0" }
  }
}

# Desired rotation window and a small safety margin
locals {
  rotation_seconds = 365 * 24 * 60 * 60
  safety_margin    = 300 # 5 minutes
}

# 1) Read the active issuer from Vault, then parse its PEM
data "vault_pki_secret_backend_issuer" "issuer" {
  backend    = var.pki_path     # e.g. "pki_int"
  issuer_ref = var.issuer_ref   # e.g. "default" or issuer ID
}

data "tls_certificate" "issuer" {
  content = data.vault_pki_secret_backend_issuer.issuer.pem_bundle
}

# 2) Compute remaining lifetime using provider functions (no shell/python)
locals {
  issuer_expiry = provider::time::rfc3339_parse(data.tls_certificate.issuer.not_after)
  now           = provider::time::rfc3339_parse(timestamp())

  seconds_until_issuer_expires = max(0, local.issuer_expiry.unix - local.now.unix)
  ttl_seconds = max(
    0,
    min(local.rotation_seconds, local.seconds_until_issuer_expires - local.safety_margin)
  )
}

# 3) Issue a cert with TTL derived from the issuer's remaining lifetime
resource "vault_pki_secret_backend_cert" "leaf" {
  backend     = var.pki_path
  name        = var.role_name
  common_name = var.cn

  ttl = "${local.ttl_seconds}s"
}
```
