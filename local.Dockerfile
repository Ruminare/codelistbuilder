FROM 833333815239.dkr.ecr.us-east-1.amazonaws.com/container-shiny:v1.1.0

USER root
RUN R --quiet -e "install.packages(c('openxlsx'), quiet = TRUE)"
USER shiny

# COPY --chown=shiny:shiny . /srv/shiny-server
COPY . /srv/shiny-server

RUN aws sts get-caller-identity

RUN aws s3 sync --quiet s3://hcie-codelist-builder/data /srv/shiny-server/data

