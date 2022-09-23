#########################
# multi stage Dockerfile
# 1. set up the build environment and build the expath-package
# 2. run the eXist-db
#########################
FROM node:10-alpine as builder
LABEL maintainer="Johannes Kepper"

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY ./ .

RUN cp existConfig.tmpl.json existConfig.json \
    && ./node_modules/.bin/gulp dist

#########################
# Now running the eXist-db
# and adding our freshly built xar-package
#########################
FROM stadlerpeter/existdb

# add specific settings
# for a production ready environment with
# bith-api as the root app.
# For more details about the options see
# https://github.com/peterstadler/existdb-docker
ENV EXIST_ENV="production"
ENV EXIST_CONTEXT_PATH="/"
ENV EXIST_DEFAULT_APP_PATH="xmldb:exist:///db/apps/bith-api"

# simply copy our xar package
# to the eXist-db autodeploy folder
COPY --from=builder /app/dist/*.xar ${EXIST_HOME}/autodeploy/
