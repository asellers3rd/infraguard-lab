# infraguard-lab

Disposable Terraform repository used as a target by the [infraguard-agent](https://github.com/asellers3rd/infraguard-agent) AI remediation agent.

Each subdirectory is an intentionally-broken scenario:

- `open-ssh/` — security group allowing SSH from `0.0.0.0/0`
- `missing-tags/` — EC2 + RDS without required cost-allocation tags
- `public-s3/` — S3 bucket with `public-read` ACL and no public access block
- `idle-compute/` — oversized always-on `m5.4xlarge` with no auto-scaling

When the agent runs a scenario it opens a pull request against `main` proposing a fix. Pull requests are reviewed in the dashboard / CLI of the infraguard-agent project — this repo only holds the lab artifacts.

Do not use any of this Terraform in a real environment.
