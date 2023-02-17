#!/bin/bash

set -e

# TODO: use templating
#    provide '.tf.tmpl' files in the 'operations/deployment' repo
#    and iterate over all of them to provide context with something like jinja
#    Example: https://github.com/mattrobenolt/jinja2-cli
#    jinja2 some_file.tmpl data.json --format=json

echo "In generate_provider.sh"

echo "
terraform {
  google = {
    source = \"hashicorp/google\"
    version = \"4.53.1\"
  }

  backend \"gcs\" {
    bucket = \"${TF_STATE_BUCKET}\"
    key    = \"tf-state\"
    # encrypt = true #AES-256encryption #TODO confirm gcp syntax
  }
}
 
data \"gcp_region\" \"current\" {}

provider \"google\" {
  project = \"${GCP_PROJECT_ID}\"
  region  = \"${GCP_DEFAULT_REGION}\"
  zone    = \"${GCP_DEFAULT_ZONE}\"
  # profile = \"default\" #TODO is this needed?
  default_tags {
    tags = merge(
      local.gcp_tags,
      var.additional_tags
    )
  }
}

resource \"google_compute_network\" \"vpc_network\" {
  name = \"terraform-network\"
}

" >> "${GITHUB_ACTION_PATH}/operations/deployment/terraform/provider.tf"