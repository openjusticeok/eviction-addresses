import pulumi
import pulumi_gcp as gcp
import pulumi_docker as docker

gcp_config = pulumi.Config('gcp')
project = gcp_config.require('project')

# Create a service account
service_account = gcp.serviceaccount.Account(
    'eviction-addresses-service-account',
    account_id='eviction-addresses-sa'
)

# Grant the service account the necessary permissions
storage_admin_binding = gcp.projects.IAMBinding(
    'eviction-addresses-storage-admin',
    role="roles/storage.admin",
    members=[pulumi.Output.concat("serviceAccount:", service_account.email)],
    project=project
)

artifact_admin_binding = gcp.projects.IAMBinding(
    'eviction-addresses-artifact-admin',
    role="roles/artifactregistry.admin",
    members=[pulumi.Output.concat("serviceAccount:", service_account.email)],
    project=project
)

document_bucket = gcp.storage.Bucket(
    'eviction-addresses-documents',
    location = "us-central1"
)

image_bucket = gcp.storage.Bucket(
    'eviction-addresses-images',
    location = "us-central1"
)

pulumi.export('document_bucket_name', document_bucket.url)
pulumi.export('image_bucket_name', image_bucket.url)


# Enable Artifact Registry API
artifact_registry_api = gcp.projects.Service("artifact_registry_api",
    service="artifactregistry.googleapis.com")

repository = gcp.artifactregistry.Repository(
    'eviction-addresses-repository',
    format='DOCKER',
    repository_id='eviction-addresses-repository',
    location='us-central1',
    opts=pulumi.ResourceOptions(depends_on=[artifact_registry_api]),
)

registry_url = pulumi.Output.concat("us-central1-docker.pkg.dev/", project, "/", repository.repository_id)

api_image_name = pulumi.Output.concat(registry_url, "/eviction-addresses-api").apply(lambda url: f'{url}:latest')

api_image = docker.Image('eviction-addresses-api-image',
             build = docker.DockerBuildArgs(
                  context = './inst/docker/',
                  dockerfile = './inst/docker/api/Dockerfile',
                  args = {
                      'BUILDKIT_INLINE_CACHE': '1'
                    },
                  builder_version = 'BuilderBuildKit',
                  platform = 'linux/amd64'
             ),
             image_name = api_image_name,
             registry = docker.RegistryArgs(
                 server = registry_url
             ),
             opts=pulumi.ResourceOptions(depends_on=[repository])
            )

pulumi.export('api_base_image_name', api_image.base_image_name)
pulumi.export('api_full_image_name', api_image.image_name)
