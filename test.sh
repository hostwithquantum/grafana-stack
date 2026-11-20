#!/bin/sh
# smoke test: start the image and check that all dashboards are provisioned
set -eu

IMAGE="${IMAGE:-quantum-grafana:dev}"
PORT="${PORT:-3999}"
URL="http://admin:test@localhost:$PORT"

id=$(docker run -d --rm --platform linux/amd64 -p "$PORT:3000" -e INITIAL_ADMIN_PASSWORD=test "$IMAGE")
trap 'docker stop "$id" >/dev/null' EXIT

i=0
until curl -sf "$URL/api/health" >/dev/null; do
	i=$((i + 1))
	[ "$i" -lt 60 ] || { echo "grafana did not start"; docker logs "$id" | tail -20; exit 1; }
	sleep 2
done

for f in dashboards/*.json; do
	uid=$(jq -r .uid "$f")
	want=$(jq -r .title "$f")
	i=0
	until got=$(curl -sf "$URL/api/dashboards/uid/$uid" | jq -r .dashboard.title) && [ "$got" = "$want" ]; do
		i=$((i + 1))
		[ "$i" -lt 15 ] || { echo "FAIL: $f ($uid) is not provisioned"; exit 1; }
		sleep 2
	done
	echo "ok: $want ($uid)"
done

# links between dashboards must point to a dashboard we ship
for uid in $(grep -oh '/d/[A-Za-z0-9_-]*' dashboards/*.json | sort -u | cut -d/ -f3); do
	curl -sf "$URL/api/dashboards/uid/$uid" >/dev/null || { echo "FAIL: link to unknown dashboard $uid"; exit 1; }
	echo "ok: link /d/$uid"
done

for ds in Logs Metrics; do
	curl -sf "$URL/api/datasources/name/$ds" >/dev/null || { echo "FAIL: datasource $ds is missing"; exit 1; }
	echo "ok: datasource $ds"
done
