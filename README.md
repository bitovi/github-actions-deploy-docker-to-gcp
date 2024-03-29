<!-- spell:disable -->
<!-- markdownlint-disable MD033 -->

# This is a Work In Progress

* Currently running locally and auth'ing with `gcloud auth`:

```shell
❯ gc auth list
   Credentialed Accounts
ACTIVE  ACCOUNT
*       maxcascone@gmail.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`
```

# Docker to GCP VM

This is a [GitHub Action](https://github.com/features/actions) that can deploy any [Docker](https://www.bitovi.com/academy/learn-docker.html)-based app
to a [Google Cloud VM](https://cloud.google.com/)
using [Docker](https://docker.com) and [Docker Compose](https://docs.docker.com/compose/).

## Outcome

The Action will:

1. Create a new VM in your Google Cloud account.
1. Copy this repo to the VM.
1. Launch this repo's application using `docker compose up`.
1. Expose the application to the Internet and provide the publicly accessible URL as an output in the GitHub GUI.

## Getting Started Intro Video

Obviously this refers to GCP but the flow is the same!

[![Getting Started - Youtube](https://img.youtube.com/vi/oya5LuHUCXc/0.jpg)](https://www.youtube.com/watch?v=oya5LuHUCXc)

## Requirements

1. Files for Docker
2. A [Google Cloud account](https://cloud.google.com/)

### 1. Files for Docker

Your app needs a `Dockerfile` and a `docker-compose.yaml` file.

> For more details on setting up Docker and Docker Compose, check out Bitovi's Academy Course: [Learn Docker](https://www.bitovi.com/academy/learn-docker.html)

### 2. A [Google Cloud account](https://cloud.google.com/)

You'll need to [enable authentication](https://cloud.google.com/docs/authentication/provide-credentials-adc?authuser=1) from a [Google Cloud account.](https://cloud.google.com/docs/get-started?authuser=1)

## Environment variables

<!-- # TODO: clarify this -->

* `repo_env` - A file in your repo that contains env vars
* `ghv_env` - An entry in [Github actions variables](https://docs.github.com/en/actions/learn-github-actions/variables)
* `dot_env` - An entry in [Github secrets](https://docs.github.com/es/actions/security-guides/encrypted-secrets)
* `gcp_secret_env` - The path to a JSON format secret in GCP

Then hook it up in your `docker-compose.yaml` file like:

```yaml
version: '3.9'
services:
  app:
    env_file: .env
```

These environment variables are merged to the `.env` file quoted in the following order:

* Terraform-passed env vars (This is not optional nor customizable)
* Repository checked-in env vars - `repo_env` file as default. (`KEY=VALUE` style)
* Github Secret - Create a secret named `DOT_ENV` - (`KEY=VALUE` style)
* GCP Secret - JSON style like `'{"key":"value"}'`

## Example usage

Create `.github/workflow/deploy.yaml` with the following content to enable an automatic build on all pushes to `main` in your repo:

```yaml
name: Basic deploy
on:
  push:
    branches: [ main ]

jobs:
  EC2-Deploy:
    runs-on: ubuntu-latest
    steps:
      - id: deploy
        uses: bitovi/github-actions-deploy-docker-to-ec2@v0.4.1
        with:
          gcp_access_key_id: ${{ secrets.GCP_ACCESS_KEY_ID }}
          gcp_default_region: us-east-1
          dot_env: ${{ secrets.DOT_ENV }}
```

### Advanced example

```yaml
name: Advanced deploy
on:
  push:
    branches: [ main ]

permissions:
  contents: read

jobs:
  EC2-Deploy:
    runs-on: ubuntu-latest
    environment:
      name: ${{ github.ref_name }}
      url: ${{ steps.deploy.outputs.vm_url }}
    steps:
    - id: deploy
      name: Deploy
      uses: bitovi/github-actions-deploy-docker-to-ec2@v0.4.1
      with:
        gcp_access_key_id: ${{ secrets.GCP_ACCESS_KEY_ID }}
        gcp_default_region: us-east-1
        domain_name: bitovi.com
        sub_domain: app
        tf_state_bucket: my-terraform-state-bucket
        dot_env: ${{ secrets.DOT_ENV }}
        ghv_env: ${{ vars.VARS }}
        app_port: 3000
        additional_tags: "{\"key1\": \"value1\",\"key2\": \"value2\"}"

```

## Customizing

### Inputs

<!-- #TODO:  review gcp specifics for ami, region, arn, buckets, etc -->
The following inputs can be used as `step.with` keys

| Name             | Type    | Description                        |
|------------------|---------|------------------------------------|
| `checkout`          | Boolean | Set to `false` if the code is already checked out (Default is `true`) (Optional) |
| `gcp_access_key_id` | String | GCP access key ID |
| `gcp_default_region` | String | GCP default region |
| `gcp_image_id` | String | GCP Machine Image ID. Will default to latest Ubuntu 22.04 server image (HVM). Accepts `ami-####` values |
| `domain_name` | String | Define the root domain name for the application. e.g. bitovi.com' |
| `sub_domain` | String | Define the sub-domain part of the URL. Defaults to `${org}-${repo}-{branch}` |
| `root_domain` | Boolean | Deploy application to root domain. Will create root and www records. Defaults to `false` |
| `cert_arn` | String | Define the certificate ARN to use for the application. **See note** |
| `create_root_cert` | Boolean | Generates and manage the root cert for the application. **See note**. Defaults to `false` |
| `create_sub_cert` | Boolean | Generates and manage the sub-domain certificate for the application. **See note**. Defaults to `false` |
| `no_cert` | Boolean | Set this to true if no certificate is present for the domain. **See note**. Defaults to `false` |
| `tf_state_bucket` | String | GCP Cloud Storage bucket to use for Terraform state. |
| `tf_state_bucket_destroy` | Boolean | Force purge and deletion of Cloud Storage bucket. Any file contained there will be destroyed. (Default is `false`). `stack_destroy` must also be `true`|
| `repo_env` | String | `.env` file containing environment variables to be used with the app. Name defaults to `repo_env`. Check **Environment variables** note |
| `dot_env` | String | `.env` file to be used with the app. This is the name of the [Github secret](https://docs.github.com/es/actions/security-guides/encrypted-secrets). Check **Environment variables** note |
| `ghv_env` | String | `.env` file to be used with the app. This is the name of the [Github variables](https://docs.github.com/en/actions/learn-github-actions/variables). Check **Environment variables** note |
| `GCP_secret_env` | String | Secret name to pull environment variables from GCP Secret Manager. Check **Environment variables** note |
| `app_port` | String | port to expose for the app |
| `lb_port` | String | Load balancer listening port. Defaults to 80 if NO FQDN provided, 443 if FQDN provided |
| `lb_healthcheck` | String | Load balancer health check string. Defaults to HTTP:app_port |
| `gvm_instance_profile` | String | The GCP IAM instance profile to use for the GCP VM instance. Default is `${GITHUB_ORG_NAME}-${GITHUB_REPO_NAME}-${GITHUB_BRANCH_NAME}` |
| `gvm_instance_type` | String | The GCP IAM instance type to use. Default is t2.small. See [this list](TODO: UPDATE) for reference |
| `stack_destroy` | String | Set to `true` to destroy the stack. Default is `""` - Will delete the elb_logs bucket after the destroy action runs. |
| `GCP_resource_identifier` | String | Set to override the GCP resource identifier for the deployment.  Defaults to `${org}-{repo}-{branch}`.  Use with destroy to destroy specific resources. |
| `app_directory` | String | Relative path for the directory of the app (i.e. where `Dockerfile` and `docker-compose.yaml` files are located). This is the directory that is copied to the EC2 instance. Default is the root of the repo. |
| `create_keypair_sm_entry` | Boolean | Generates and manage a secret manager entry that contains the public and private keys created for the ec2 instance. |
| `additional_tags` | JSON | Add additional tags to the terraform [default tags](https://www.hashicorp.com/blog/default-tags-in-the-terraform-GCP-provider), any tags put here will be added to all provisioned resources.|

## Note about resource identifiers

Most resources will contain the tag GITHUB_ORG-GITHUB_REPO-GITHUB_BRANCH, some of them, even the resource name after. 
We limit this to a 60 characters string because some GCP resources have a length limit and short it if needed.

We use the kubernetes style for this. For example, kubernetes -> k(# of characters)s -> k8s. And so you might see some compressions are made.

For some specific resources, we have a 32 characters limit. If the identifier length exceeds this number after compression, we remove the middle part and replace it for a hash made up from the string itself.

### S3 buckets naming

Buckets names can be made of up to 63 characters. If the length allows us to add -tf-state, we will do so. If not, a simple -tf will be added.

## CERTIFICATES - Only for GCP Managed domains via Google Cloud DNS

As a default, the application will be deployed and the public URL will be displayed.

If `domain_name` is defined, we will look up for a certificate with the name of that domain (eg. `example.com`). We expect that certificate to contain both `example.com` and `*.example.com`. 

If you wish to set up `domain_name` and disable the certificate lookup, set up `no_cert` to true.

Setting `create_root_cert` to `true` will create this certificate with both `example.com` and `*.example.com` for you, and validate them. (DNS validation).

Setting `create_sub_cert` to `true` will create a certificate **just for the subdomain**, and validate it.

:warning: **Keep in mind that managed certificates will be deleted if stack_destroy is set to true** :warning:

To change a certificate (root_cert, sub_cert, ARN or pre-existing root cert), you must first set the `no_cert` flag to true, run the action, then set the `no_cert` flag to false, add the desired settings and excecute the action again. (**This will destroy the first certificate.**)

This is necessary due to a limitation that prevents certificates from being changed while in use by certain resources.

## Made with BitOps

[BitOps](https://bitops.sh) allows you to define Infrastructure-as-Code for multiple tools in a central place.  This action uses a BitOps [Operations Repository](https://bitops.sh/operations-repo-structure/) to set up the necessary Terraform and Ansible to create infrastructure and deploy to it.

## Contributing

We would love for you to contribute to [bitovi/github-actions-deploy-docker-to-ec2](https://github.com/bitovi/github-actions-deploy-docker-to-ec2)!.   

[Issues](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/issues) and [Pull Requests](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/pulls) are welcome!

## License

The scripts and documentation in this project are released under the [MIT License](https://github.com/bitovi/github-actions-deploy-docker-to-ec2/blob/main/LICENSE).

## Provided by Bitovi

[Bitovi](https://www.bitovi.com/) is a proud supporter of Open Source software.

## Need help or have questions?
You can **get help or ask questions** on [Discord channel](https://discord.gg/J7ejFsZnJ4)! Come hangout with us!

Or, you can hire us for training, consulting, or development. [Set up a free consultation](https://www.bitovi.com/devops-consulting).
