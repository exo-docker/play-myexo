# Runtime configuration overrides

This directory is mounted into the container at `${MY_EXO_APPDIR}/conf` (see the `SPRING_CONFIG_ADDITIONAL_LOCATION`
environment variable in the `Dockerfile`). Drop an `application.yml` or `application-<profile>.yml` file here to
override any setting baked into the my-exo jar without rebuilding the image — for example:

```yaml
spring:
  datasource:
    password: some-secret-not-committed-anywhere
```

This replaces the old Play-era convention of bind-mounting `conf/application.conf`. If nothing is mounted here,
the image runs entirely on its baked-in `application.yml` defaults plus whatever environment variables are set
(`DB_PASSWORD`, `MYEXO_BASE_URL`, `APP_MODE`, `DB_HOST`, `DB_PORT`).
