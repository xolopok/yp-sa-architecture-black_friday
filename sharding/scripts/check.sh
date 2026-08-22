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
echo "Всего документов"
"${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet --eval \
  'db.getSiblingDB("somedb").helloDoc.countDocuments({})'
echo
echo "Шард 1 (db_shard_1)"
"${COMPOSE_CMD[@]}" exec -T db_router mongosh \
  "mongodb://db_shard_1:27018/?replicaSet=shard1rs" --quiet --eval \
  'db.getSiblingDB("somedb").helloDoc.countDocuments({})'
echo
echo "Шард 2 (db_shard_2)"
"${COMPOSE_CMD[@]}" exec -T db_router mongosh \
  "mongodb://db_shard_2:27018/?replicaSet=shard2rs" --quiet --eval \
  'db.getSiblingDB("somedb").helloDoc.countDocuments({})'
echo
echo "Распределение по шардам"
"${COMPOSE_CMD[@]}" exec -T db_router mongosh --quiet --eval \
  'db.getSiblingDB("somedb").helloDoc.getShardDistribution()'
