# Roadpass DevOps Assignment

Submission for the Roadpass Digital DevOps assignment: Terraform/Terragrunt VPC and EC2 app stack, Packer + Ansible AMI, Helm chart for nginx with ingress, and a GitHub Actions workflow using OIDC to deploy to EKS staging.

---

## 1. Assignment overview

This repo contains:

- A **Terraform VPC module** for a staging VPC (172.16.0.0/16) with two AZs, public/private subnets, NAT gateways, and SSM/S3 endpoints, plus Terragrunt usage under `terraform/live/staging/vpc`.
- A **Packer + Ansible** pipeline that builds an Amazon Linux 2023 AMI with nginx and a pack/fry pattern: pack bakes the image; fry is implemented via user data at launch.
- A **Terraform EC2-app module** (ASG of 2 instances, ALB, launch template, IAM, security groups) and Terragrunt usage under `terraform/live/staging/ec2-app`.
- A **Helm chart** (`helm/nginx-app`) for nginx with a configurable Ingress (nginx or ALB controller).
- A **GitHub Actions workflow** that uses GitHub OIDC to assume an AWS role and deploy the Helm chart to a staging EKS cluster.

---

## 2. Repo structure

```
roadpass-devops-assignment/
├── README.md
├── .gitignore
├── terragrunt.hcl
├── .github/
│   └── workflows/
│       └── deploy.yml
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── ec2-app/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── live/
│       └── staging/
│           ├── vpc/
│           │   └── terragrunt.hcl
│           └── ec2-app/
│               └── terragrunt.hcl
├── packer/
│   ├── nginx-ami.pkr.hcl
│   └── ansible/
│       ├── playbook.yml
│       └── roles/
│           ├── pack/
│           │   ├── tasks/
│           │   │   └── main.yml
│           │   └── files/
│           │       └── render-index.sh
│           └── fry/
│               └── README.md
└── helm/
    └── nginx-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── _helpers.tpl
            ├── deployment.yaml
            ├── service.yaml
            └── ingress.yaml
```

---

## 3. VPC design

- **Supernet:** 172.16.0.0/16.
- **Availability zones:** Two AZs (e.g. us-east-1a, us-east-1b). Four public subnets and four private subnets (two of each per AZ).
- **Subnet layout:**
  - Public: 172.16.0.0/20, 172.16.16.0/20 (AZ1), 172.16.32.0/20, 172.16.48.0/20 (AZ2).
  - Private: 172.16.64.0/20, 172.16.80.0/20 (AZ1), 172.16.96.0/20, 172.16.112.0/20 (AZ2).
- **Routing:** One shared public route table with a default route to the Internet Gateway. One private route table per AZ, each with a default route to a NAT gateway in the same AZ (high availability).
- **Endpoints:** Interface endpoints for SSM, ec2messages, and ssmmessages (in private subnets, with a security group allowing HTTPS from the VPC). Gateway endpoint for S3 attached to the private route tables.

---

## 4. AMI build process

- **Packer** (`packer/nginx-ami.pkr.hcl`) uses the Amazon Linux 2023 AMI and runs an Ansible playbook.
- **Pack role:** Installs nginx, creates a default `/usr/share/nginx/html/index.html` placeholder, installs `/usr/local/bin/render-index.sh`, enables and starts nginx. The baked page states that runtime values will appear after launch.
- **Fry role:** Runtime customization is done at instance boot. The EC2 launch template user data writes variables to `/etc/default/nginx-app` (e.g. APP_NAME, ENVIRONMENT, MESSAGE), runs `render-index.sh` to regenerate the landing page, and restarts nginx. The fry contract is documented in `packer/ansible/roles/fry/README.md`; the Terraform ec2-app module implements it via user data.

User data example (as used in the launch template):

```bash
#!/bin/bash
cat >/etc/default/nginx-app <<EOF
APP_NAME=roadpass-demo
ENVIRONMENT=staging
MESSAGE=Hello from userdata
EOF
/usr/local/bin/render-index.sh
systemctl restart nginx
```

---

## 5. EC2 app stack

- **ALB** in public subnets; **ASG** (2 instances) in private subnets.
- **Launch template:** Uses the Packer-built AMI ID, IAM instance profile (AmazonSSMManagedInstanceCore for SSM Session Manager), and user data for fry variables.
- **Security groups:** ALB SG allows HTTP (and optionally HTTPS) from 0.0.0.0/0 and forwards to the EC2 SG on port 80. EC2 SG allows 80 from the ALB and 22 from configurable CIDRs (e.g. VPN/bastion).
- **SSH access:** Instances are in private subnets. Direct SSH from the internet is not possible. Use **SSM Session Manager** (recommended, given the SSM endpoints and instance profile) or SSH via a bastion/jump host in a public subnet. Restrict `ssh_allowed_cidrs` to your operational CIDRs.

---

## 6. Helm chart

The `helm/nginx-app` chart runs nginx with a Deployment, ClusterIP Service, and optional Ingress.

- **Values:** `replicaCount`, `image.repository`/`image.tag`, `service.port`, `ingress.enabled`/`ingress.className`/`ingress.host`/`ingress.path`/`ingress.pathType`/`ingress.annotations`/`ingress.tls`, `resources`.
- **Ingress:** Works with an nginx or ALB ingress controller; set `ingress.className` and annotations in `values.yaml` as needed.

To dump the rendered templates:

```bash
helm template nginx-app ./helm/nginx-app -f ./helm/nginx-app/values.yaml
```

---

## 7. GitHub Actions deployment

The workflow `.github/workflows/deploy.yml`:

- Triggers on push to `main` and on `workflow_dispatch`.
- Uses **GitHub OIDC** with `aws-actions/configure-aws-credentials@v4` and `role-to-assume: ${{ secrets.AWS_ROLE_ARN }}` (no long-lived AWS keys).
- Installs kubectl and Helm, runs `aws eks update-kubeconfig` for the staging EKS cluster, then runs `helm upgrade --install nginx-app ./helm/nginx-app --namespace staging --create-namespace -f ./helm/nginx-app/values.yaml`.

**AWS setup required:**

1. Create an **IAM OIDC identity provider** for GitHub (e.g. `token.actions.githubusercontent.com`).
2. Create an **IAM role** with a trust policy allowing the GitHub repo (and optionally branch) to assume it via OIDC.
3. Attach policies so the role can call `eks:DescribeCluster` and run `aws eks update-kubeconfig`, and can perform the Kubernetes operations needed for the Helm release (e.g. EKS cluster access via an associated access entry or aws-auth).
4. Set the role ARN as the GitHub repository secret **AWS_ROLE_ARN**. Set **EKS_CLUSTER_NAME** and **AWS_REGION** in the workflow or as variables if you use different values.

---

## 8. Commands

| Task | Command |
|-----|--------|
| Packer init | `packer init packer/nginx-ami.pkr.hcl` |
| Packer validate | `packer validate packer/nginx-ami.pkr.hcl` |
| Packer build | `packer build packer/nginx-ami.pkr.hcl` |
| VPC plan | `cd terraform/live/staging/vpc && terragrunt plan` |
| EC2-app plan | `cd terraform/live/staging/ec2-app && terragrunt plan` (after VPC; set `ami_id` to built AMI) |
| Helm template | `helm template nginx-app ./helm/nginx-app -f ./helm/nginx-app/values.yaml` |
| Helm deploy (local) | `helm upgrade --install nginx-app ./helm/nginx-app --namespace staging --create-namespace -f ./helm/nginx-app/values.yaml` |
| Terraform fmt | `terraform fmt -recursive` |
| Terragrunt fmt | `terragrunt hclfmt` |

---

## 9. Assumptions and tradeoffs

- **SSH:** EC2 instances are in private subnets. SSH is only via SSM Session Manager or a bastion; the SG allows SSH from configurable CIDRs for the latter.
- **ACM/TLS:** The ec2-app module supports an optional `certificate_arn` for an HTTPS listener and HTTP→HTTPS redirect; it is left unset in the example.
- **AMI ID:** The staging ec2-app Terragrunt uses `ami_id = "ami-placeholder"`. Replace with the AMI ID from `packer build` before applying.
- **Infrastructure as code:** The code is intended to be applied in an AWS account; Terragrunt plan is validated but deployment is at the user’s discretion.
- **EKS cluster:** The GitHub Actions workflow assumes a staging EKS cluster already exists; it does not create the cluster.

---

## 10. Time spent

Approximately 6 hours over 2 days
