"""A Google Cloud Python Pulumi program"""

import pulumi
from pulumi_gcp import storage, projects, cloudbuild, compute

# Create a new GCP project
project = projects.Project('eviction-addresses')

# Create a GCP resource (Storage Bucket)
bucket = storage.Bucket('my-bucket', location="US")

# Export the DNS name of the bucket
pulumi.export('bucket_name', bucket.url)

# Create a Google Cloud Build trigger
api_trigger = cloudbuild.Trigger('eviction-addresses-api-trigger',
  description='A trigger for the eviction-addresses-api',
  github={
    'owner': 'openjusticeok',
    'name': 'eviction-addresses',
    'push': {
      'branch': 'main',
    },
  },
  substitutions={
    'bucket_name': bucket.name,
  },
  filename='cloudbuild.yaml',
)

dashboard_trigger = cloudbuild.Trigger('eviction-addresses-dashboard-trigger')

job_trigger = cloudbuild.Trigger('my-job-trigger')
