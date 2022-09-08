library(googleCloudRunner)

#library(containerit)
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
    cr_buildstep_secret(
      secret = "eviction-addresses-api-config",
      decrypted = "api/config.yml"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-api-renviron",
      decrypted = "api/.Renviron"
    ),
    cr_buildstep_bash("mkdir -p api/shiny-apps-certs/"),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-cert",
      decrypted = "api/shiny-apps-certs/client-cert.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-key",
      decrypted = "api/shiny-apps-certs/client-key.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-ca",
      decrypted = "api/shiny-apps-certs/server-ca.pem"
    ),
    cr_buildstep_bash("chmod 0600 api/shiny-apps-certs/client-key.pem"),
    cr_buildstep_docker(
      image = "eviction-addresses-api",
      dir = "api",
      kaniko_cache = T
    ),
    cr_buildstep_run(
      name = "eviction-addresses-api",
      image = "gcr.io/ojo-database/eviction-addresses-api:$BUILD_ID",
      port = 3838,
      memory = "2G",
      cpu = 1,
      max_instances = 1,
      concurrency = 80,
      allowUnauthenticated = F,
      gcloud_args = c("--timeout=3600")
    )
  ),
  timeout = 7200
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
  includedFiles = "**"
)




# dashboard_dockerfile <- containerit::dockerfile(
#   image = "rocker/shiny",
#   from = "dashboard/server.R",
#   filter_baseimage_pkgs = T
# )
# 
# write(dashboard_dockerfile, file = "dashboard/sample-Dockerfile")


eviction_addresses_dashboard_yaml <- cr_build_yaml(
  steps = c(
    cr_buildstep_secret(
      secret = "eviction-addresses-client-id",
      decrypted = "dashboard/client-id.json"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-dashboard-renviron",
      decrypted = "dashboard/.Renviron"
    ),
    # cr_buildstep_secret(
    #   secret = "eviction-addresses-dashboard-service-account",
    #   decrypted = "dashboard/eviction-addresses-dashboard-service-account.json"
    # ),
    cr_buildstep_secret(
      secret = "eviction-addresses-service-account",
      decrypted = "dashboard/eviction-addresses-service-account.json"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-api-config",
      decrypted = "dashboard/config.yml"
    ),
    cr_buildstep_bash("mkdir -p dashboard/shiny-apps-certs/"),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-cert",
      decrypted = "dashboard/shiny-apps-certs/client-cert.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-key",
      decrypted = "dashboard/shiny-apps-certs/client-key.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-ca",
      decrypted = "dashboard/shiny-apps-certs/server-ca.pem"
    ),
    cr_buildstep_bash("chmod 0600 dashboard/shiny-apps-certs/client-key.pem"),
    cr_buildstep_docker(
      image = "eviction-addresses-dashboard",
      dir = "dashboard",
      kaniko_cache = T
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
  timeout = 7200
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


###### Test JWT generation ##########

# cr <- cr_run_get("eviction-addresses-api")
# url <- cr$status$url
# jwt <- cr_jwt_create(url)
# token <- cr_jwt_token(jwt, url)
# 
# library(httr)
# res <- cr_jwt_with_httr(
#   GET(str_c(url, "/case")),
#   token
# )
# content(res)


