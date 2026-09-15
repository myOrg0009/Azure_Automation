## Decision: Added NSG to every subnet by default 
**Why:** Checkov CKV2_AZURE_31 — enterprise security baseline
requires every subnet to have an NSG. Good practice regardless
of the check — NSGs provide subnet-level traffic control.
**Default rules:** No inbound/outbound rules defined at module
level — specific rules added per environment as needed.


## Decision: AKS Checkov checks

**Fixed CKV_AZURE_168 (max_pods=50):** Default AKS max pods is 30.
Setting 50 is a genuine best practice — more pods per node =
better bin packing, fewer nodes needed at scale. No cost impact.

**Fixed CKV_AZURE_226 (ephemeral OS disk):** Ephemeral disks use
the node's local SSD instead of a managed disk. Faster I/O,
lower latency, no extra cost. Better for dev and prod.

**Skipped CKV_AZURE_170 (Paid SKU):** Free SKU for dev. Paid SKU
(~$70/month) enforced in staging/prod where SLA matters.

**Skipped CKV_AZURE_232 (system node taint):** Single node pool
in dev is fine. Separate system/user node pools added 

**Skipped CKV_AZURE_172 (Secrets Store CSI):** Key Vault + CSI
driver integration. Skipping until that module exists.

> Running log of every technical decision made in this project.
> Format: what, why, alternatives considered, when to revisit.

---

### Decision: Azure Blob Storage over HCP Terraform for state
**What:** Terraform state stored in Azure Blob Storage container
**Why:** Azure-native, no third-party dependency, forces understanding
of state locking, corruption recovery, and import operations
**Alternative considered:** HCP Terraform Cloud — rejected because it
abstracts away state management learning and adds a third-party
dependency to an Azure-native stack
**Revisit:** Never — this is the right long-term choice

---

### Decision: Azure CNI over kubenet for AKS networking
**What:** AKS configured with network_plugin = "azure" (Azure CNI)
**Why:** Pods get real VNet IPs, enabling Azure-level network policy
enforcement. Better performance (no NAT overhead). Required for
certain Azure integrations like Application Gateway Ingress
**Alternative considered:** kubenet — simpler but limited network
policy support and no real VNet IPs for pods
**Cost:** Larger subnet needed — /24 for dev, /22 for prod
**Revisit:** Never for prod. Fine to keep for all environments.

---

### Decision: SystemAssigned managed identity for AKS
**What:** AKS uses SystemAssigned identity instead of service principal
**Why:** Azure manages the identity lifecycle. No credentials to
create, store, or rotate. Identity deleted with the cluster.
Nothing to leak, nothing to forget to rotate.
**Alternative considered:** Service principal with client secret —
rejected because secret rotation is manual overhead and a leaked
secret means compromised cluster access
**Revisit:** Never — managed identity is always preferred

---

### Decision: ACR Basic SKU for dev
**What:** Azure Container Registry using Basic tier
**Why:** Dev environment — Basic tier is sufficient for building
and testing. No geo-replication or private endpoints needed yet.
Cost: ~$5/month vs ~$175/month for Premium
**Alternative considered:** Premium SKU — rejected for dev due to cost
**Revisit:** — upgrade to Standard/Premium for staging/prod
when private endpoints and geo-replication are needed

---

### Decision: Manual approval gate before terraform apply
**What:** Azure DevOps environment gate requiring manual approval
before every terraform apply
**Why:** Nothing reaches Azure without a human reviewing the plan
first. Prevents accidental applies. Builds review habit early.
In a real team, approver is different from the code author.
**Alternative considered:** Auto-apply — rejected because automation
without review is how production outages happen
**Revisit:** Never — approval gate stays for all environments

---

### Decision: Separate state file per environment
**What:** dev.tfstate, staging.tfstate, prod.tfstate in same container
**Why:** A failed apply in dev cannot corrupt prod state. A terraform
destroy in dev only destroys dev. State isolation = environment isolation
**Alternative considered:** Single state file with workspaces —
rejected because workspace isolation is logical not physical,
a corrupted state file affects all workspaces
**Revisit:** Never

---

## Checkov Decisions

### Fixed: CKV_AZURE_168 — max_pods = 50
**What:** Added max_pods = 50 to AKS default node pool
**Why:** Default AKS max pods is 30. Setting 50 is best practice —
better bin packing, fewer nodes needed at scale. No cost impact.

---

### Fixed: CKV_AZURE_226 — Ephemeral OS disk
**What:** Added os_disk_type = "Ephemeral" to AKS node pool
**Why:** Uses node's local SSD instead of managed disk. Faster I/O,
lower latency, no extra cost. Better for dev and prod.

---

### Fixed: CKV_AZURE_141 — Disable local admin account
**What:** Added local_account_disabled = true to AKS cluster
**Why:** Local admin account bypasses Azure AD authentication.
Disabling it forces all access through Azure AD — proper IAM.

---

### Fixed: CKV_AZURE_4 — Azure Monitor logging
**What:** Added oms_agent block with Log Analytics workspace
**Why:** Cluster logs and metrics forwarded to Log Analytics.
---

### Fixed: CKV_AZURE_116 — Azure Policy add-on
**What:** Added azure_policy_enabled = true to AKS cluster
**Why:** Enables Azure Policy enforcement at the pod level.
---

### Skipped: CKV_AZURE_170 — Paid SKU for SLA
**Why skipped:** Dev environment. Paid SKU adds ~$70/month.
**When to fix:** Enforce Standard SKU in staging/prod environments.

---

### Skipped: CKV_AZURE_232 — System node taint
**Why skipped:** Single node pool in dev. Taint requires separate
system and user node pools
**Fix:**- add dedicated system node pool.

---

### Skipped: CKV_AZURE_172 — Secrets Store CSI autorotation
**Why skipped:** Key Vault integration doesn't exist yet.
**Fix:** — wire Key Vault + CSI driver.

---

### Skipped: CKV_AZURE_6 — API server authorized IP ranges
**Why skipped:** Azure DevOps pipeline agents use dynamic IPs.
Whitelisting them is not practical without a self-hosted agent.
**Fix:** — if self-hosted agent is added, restrict
API server access to agent subnet IP range.

---

### Skipped: CKV_AZURE_117 — Disk encryption set
**Why skipped:** Requires a Key Vault-backed disk encryption set.
Key Vault module doesn't exist yet.
**Fix:** — create Key Vault module first.

---

### Skipped: CKV_AZURE_115 — Private cluster
**Why skipped:** Private AKS cluster requires private DNS zone
and VPN/ExpressRoute or jump host for access. Out of scope for dev.
**Fix:**— Landing Zone Factory will include private
cluster option for prod environments.

---

### Skipped: CKV_AZURE_227 — Temp disk encryption
**Why skipped:** Requires disk encryption set backed by Key Vault.
**Fix:**— alongside disk encryption set.

---

### Skipped: CKV_AZURE_171 — Upgrade channel
**Why skipped:** automatic_channel_upgrade attribute not supported
in current azurerm provider version.
**Fix:** — upgrade provider version, add
automatic_channel_upgrade = "stable".

---

### Skipped: CKV_AZURE_139, 237, 233, 165, 166, 164, 163, 167 — ACR Premium features
**Why skipped:** All require Premium SKU (~$175/month).
Basic SKU is sufficient for dev — image storage and pull works fine.
We use Trivy in the pipeline for vulnerability scanning (CKV_AZURE_163)
instead of ACR's native scanning.
**Fix:** — upgrade ACR to Standard/Premium for
staging/prod and enable private endpoints, geo-replication, and
native vulnerability scanning.

### Decision: Azure AD integration enabled on AKS
**Why:** local_account_disabled = true requires Azure AD integration
since K8s 1.25. Azure AD managed integration is the correct enterprise
approach anyway — all cluster access goes through Azure AD, no local
admin accounts, full audit trail of who accessed what.
**azure_rbac_enabled = true:** Kubernetes authorization handled by
Azure RBAC instead of native K8s RBAC. Simpler — one permission
system for both Azure resources and K8s cluster access.

### Decision: AKS service CIDR 172.16.0.0/16
**Why:** Default service CIDR 10.0.0.0/16 conflicts with VNet
address space. Using 172.16.0.0/16 (private range, no overlap).
dns_service_ip 172.16.0.10 must be inside service_cidr.

### Decision: OIDC issuer enabled on AKS
**Why:** Azure enabled OIDC on cluster during initial creation.
Cannot be disabled once enabled. Keeping it enabled is correct
long-term — OIDC issuer is required for Workload Identity
which we'll use for pod-level managed identity.
