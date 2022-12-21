library(googleCloudRunner)

eviction_addresses_api_yaml <- cr_build_yaml(
  steps = c(
    cr_buildstep_secret(
      secret = "eviction-addresses-service-account",
      decrypted = "/workspace/eviction-addresses-service-account.json"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-api-config",
      decrypted = "/workspace/config.yml"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-api-renviron",
      decrypted = "/workspace/.Renviron"
    ),
    cr_buildstep_bash("mkdir -p /workspace/shiny-apps-certs/"),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-cert",
      decrypted = "/workspace/shiny-apps-certs/client-cert.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-key",
      decrypted = "/workspace/shiny-apps-certs/client-key.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-ca",
      decrypted = "/workspace/shiny-apps-certs/server-ca.pem"
    ),
    cr_buildstep_bash("chmod 0600 /workspace/shiny-apps-certs/client-key.pem"),
    cr_buildstep_bash("cp inst/cloudbuild/Dockerfile ./Dockerfile"),
    cr_buildstep_docker(
      image = "eviction-addresses-api",
      kaniko_cache = FALSE
    ),
    cr_buildstep_run(
      name = "eviction-addresses-api",
      image = "gcr.io/ojo-database/eviction-addresses-api:$BUILD_ID",
      port = 3838,
      memory = "2G",
      cpu = 1,
      max_instances = 1,
      concurrency = 80,
      allowUnauthenticated = FALSE,
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


eviction_addresses_dashboard_yaml <- cr_build_yaml(
  steps = c(
    cr_buildstep_secret(
      secret = "eviction-addresses-client-id",
      decrypted = "/workspace/client-id.json"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-dashboard-renviron",
      decrypted = "/workspace/.Renviron"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-dashboard-service-account",
      decrypted = "/workspace/eviction-addresses-dashboard-service-account.json"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-service-account",
      decrypted = "/workspace/eviction-addresses-service-account.json"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-api-config",
      decrypted = "/workspace/config.yml"
    ),
    cr_buildstep_bash("mkdir -p /workspace/shiny-apps-certs/"),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-cert",
      decrypted = "/workspace/shiny-apps-certs/client-cert.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-key",
      decrypted = "/workspace/shiny-apps-certs/client-key.pem"
    ),
    cr_buildstep_secret(
      secret = "eviction-addresses-ssl-ca",
      decrypted = "/workspace/shiny-apps-certs/server-ca.pem"
    ),
    cr_buildstep_bash("chmod 0600 /workspace/shiny-apps-certs/client-key.pem"),
    cr_buildstep_bash("cp inst/cloudbuild/shiny_Dockerfile ./Dockerfile"),
    cr_buildstep_docker(
      image = "eviction-addresses-dashboard",
      kaniko_cache = FALSE
    ),
    cr_buildstep_run(
      name = "eviction-addresses-dashboard",
      image = "gcr.io/ojo-database/eviction-addresses-dashboard:$BUILD_ID",
      port = 3838,
      memory = "1G",
      cpu = 1,
      max_instances = 1,
      concurrency = 80,
      gcloud_args = c("--timeout=3600")
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
cr <- cr_run_get("eviction-addresses-api")
url <- cr$status$url
jwt <- cr_jwt_create(url)
token <- cr_jwt_token(jwt, url)

library(httr)
library(stringr)
res <- cr_jwt_with_httr(
  GET(str_c(url, "/dbpingfuture")),
  token
)
content(res)

res <- cr_jwt_with_httr(
  GET(str_c(url, "/refresh/documents/10")),
  token
)
content(res)

res <- cr_jwt_with_httr(
  GET(str_c(url, "/refresh")),
  token
)
content(res)

b <- format_postgrid_request(
  line1 = "13243 S 68 E AVE",
  city = "Bixby",
  state = "OK",
  zip = "74008"
)
res <- send_postgrid_request("config.yml", b, geocode = TRUE)
