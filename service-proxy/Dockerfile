# service-proxy
# this dockerfile installs and configures a privoxy that is used for the
# internal services to communicate with the internet. It sets up a default
# configuration that is adapted by the docker-compose.yml
# unfortunately this has to be a image on the host build prior to running
# otherwise the service-proxy would need internet access for apk-add
FROM alpine:edge
RUN apk add --no-cache privoxy sudo curl && rm -rf /var/cache/apk/* \
  && mv /etc/privoxy/config.new /etc/privoxy/config \
  && mv /etc/privoxy/default.action.new /etc/privoxy/default.action \
  && mv /etc/privoxy/user.action.new /etc/privoxy/user.action \
  && mv /etc/privoxy/default.filter.new /etc/privoxy/default.filter \
  && mv /etc/privoxy/user.filter.new /etc/privoxy/user.filter \
  && mv /etc/privoxy/regression-tests.action.new /etc/privoxy/regression-tests.action \
  && mv /etc/privoxy/trust.new /etc/privoxy/trust \
  && mv /etc/privoxy/match-all.action.new /etc/privoxy/match-all.action
