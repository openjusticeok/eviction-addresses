library(googleCloudRunner)

# library(containerit)
# 
# api_dockerfile <- containerit::dockerfile(from = "api/plumber.R",
#                                           filter_baseimage_pkgs = T)
# 
# write(api_dockerfile, file = "api/Dockerfile")

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
      concurrency = 80,
      allowUnauthenticated = F
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

cr_buildtrigger_delete("eviction-addresses-api-trigger")

cr_buildtrigger(
  build = eviction_addresses_api_build,
  name = "eviction-addresses-api-trigger",
  trigger = eviction_addresses_api_trigger,
  includedFiles = "api/**"
)



# library(containerit)
# 
# dashboard_dockerfile <- containerit::dockerfile(from = "dashboard/server.R",
#                                           filter_baseimage_pkgs = T)
# 
# write(dashboard_dockerfile, file = "dashboard/Dockerfile")


eviction_addresses_dashboard_yaml <- cr_build_yaml(
  steps = c(
    cr_buildstep_secret(
      secret = "eviction-addresses-service-account",
      decrypted = "/srv/shiny-server/eviction-addresses-service-account.json"
    ),
    cr_buildstep_docker(
      image = "eviction-addresses-dashboard",
      dir = "dashboard"
    ),
    cr_buildstep_run(
      name = "eviction-addresses-dashboard",
      image = "gcr.io/ojo-database/eviction-addresses-dashboard:$BUILD_ID",
      port = 3838,
      memory = "1G",
      cpu = 1,
      max_instances = 1,
      concurrency = 80
    )
  ),
  timeout = 900
)

eviction_addresses_dashboard_build <- cr_build_make(
  yaml = eviction_addresses_dashboard_yaml
)

eviction_addresses_dashboard_trigger <- cr_buildtrigger_repo(
  repo_name = "openjusticeok/eviction-addresses",
  branch = "main"
)

cr_buildtrigger_delete("eviction-addresses-dashboard-trigger")

cr_buildtrigger(
  build = eviction_addresses_dashboard_build,
  name = "eviction-addresses-dashboard-trigger",
  trigger = eviction_addresses_dashboard_trigger,
  includedFiles = "**"
)





