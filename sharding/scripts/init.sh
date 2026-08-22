#!/usr/bin/env bash
set -euo pipefail

if [ -n "${COMPOSE:-}" ]; then
  COMPOSE_CMD=(${COMPOSE})
elif command -v docker >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
elif command -v podman >/dev/null 2>&1; then
  COMPOSE_CMD=(podman compose)
else
  echo "Невозможно выполнить: не найден ни docker, ни podman." >&2
  exit 1
fi
echo "Контейнерный движок: ${COMPOSE_CMD[*]}"
echo
echo "Инициализация"
"${COMPOSE_CMD[@]}" exec -T db_cfg mongosh --port 27019 --quiet --eval \
  'rs.initiate({_id: "cfgrs", members: [{_id: 0, host: "db_cfg:27019"}]})'
"${COMPOSE_CMD[@]}" exec -T db_shard_1 mongosh --port 27018 --quiet --eval \
  'rs.initiate({_id: "shard1rs", members: [{_id: 0, host: "db_shard_1:27018"}]})'
"${COMPOSE_CMD[@]}" exec -T db_shard_2 mongosh --port 27018 --quiet --eval \
  'rs.initiate({_id: "shard2rs", members: [{_id: 0, host: "db_shard_2:27018"}]})'
for i in $(seq 1 60); do
  state="$("${COMPOSE_CMD[@]}" exec -T db_cfg mongosh --port 27019 --quiet --eval 'try { rs.status().myState } catch (e) { -1 }' 2>/dev/null || true)"
  if [ "$state" = "1" ]; then
    break
  fi
  sleep 2
done
for i in $(seq 1 60); do
  if "${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet --eval \
      'sh.addShard("shard1rs/db_shard_1:27018")' >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
for i in $(seq 1 60); do
  if "${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet --eval \
      'sh.addShard("shard2rs/db_shard_2:27018")' >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
"${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet --eval 'sh.enableSharding("somedb")'
"${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet --eval \
  'sh.shardCollection("somedb.helloDoc", {_id: "hashed"}, false, {numInitialChunks: 2})'
echo
echo "Наполнение данными"
"${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet <<'EOF'
use somedb
for (var i = 0; i < 2000; i++) { db.helloDoc.insertOne({ age: i, name: "ly" + i }) }
EOF
echo
echo "Готово"