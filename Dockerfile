FROM r.planetary-quantum.com/docker-hub-proxy/grafana/grafana-oss:10.4.2

# install https://github.com/noqcks/gucci (CLI templating)
USER root
RUN export VERSION=1.2.2 && cd /tmp && \
    wget -q https://github.com/noqcks/gucci/releases/download/${VERSION}/gucci-v${VERSION}-linux-amd64 && \
    chmod +x gucci-v${VERSION}-linux-amd64 && \
    mv gucci-v${VERSION}-linux-amd64 /usr/local/bin/gucci
USER grafana

COPY --chown=grafana datasource.tpl.yaml /tmp/datasource.tpl.yaml
COPY --chown=grafana dashboard-provider.yaml /etc/grafana/provisioning/dashboards/dashboard-provider.yml
COPY --chown=grafana swarm-dashboard.json /var/lib/grafana/dashboards/swarm.json

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["export GF_SECURITY_ADMIN_PASSWORD=\"$INITIAL_ADMIN_PASSWORD\" && gucci /tmp/datasource.tpl.yaml > /etc/grafana/provisioning/datasources/loki.yml && /run.sh"]
