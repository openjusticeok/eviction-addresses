library(googleCloudRunner)

# library(containerit)
# 
# api_dockerfile <- containerit::dockerfile(from = "api/plumber.R",
#                                           filter_baseimage_pkgs = T,
#                                           copy = "script_dir")

eviction_addresses_api_yaml <- cr_build_yaml(
  steps = c(
    cr_buildstep_secret(
      secret = "eviction-addresses-service-account",
      decrypted = "api/eviction-addresses-service-account.json"
    ),
    # cr_buildstep_secret(
    #   secret = "eviction-addresses-r-config",
    #   decrypted = "api/config.yml"
    # ),
    cr_buildstep_docker(
      image = "eviction-addresses-api",
      dir = "api"
    ),
    cr_buildstep_run(
      name = "eviction-addresses-api",
      image = "gcr.io/ojo-database/eviction-addresses-api:$BUILD_ID",
      port = 3838,
      memory = "2G",
      cpu = 1,
      concurrency = 80
    )
  )
)

eviction_addresses_api_build <- cr_build_make(
  yaml = eviction_addresses_api_yaml
)

eviction_addresses_api_trigger <- cr_buildtrigger_repo(
  repo_name = "openjusticeok/eviction-addresses",
  branch = "main"
)

cr_buildtrigger(
  build = eviction_addresses_api_build,
  name = "eviction-addresses-api-trigger",
  trigger = eviction_addresses_api_trigger,
  includedFiles = "api/**"
)


