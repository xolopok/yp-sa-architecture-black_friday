# Мобильный мир: шардирование

![Диаграмма](../docs/architecture/stage1.png)

## Состав

| Контейнер    | Тип                                            | Порт  |
|--------------|------------------------------------------------|-------|
| `db_cfg`     | Конфиг (`mongod`, `--configsvr`, rs `cfgrs`)   | 27019 |
| `db_shard_1` | Шард 1 (`mongod`, `--shardsvr`, rs `shard1rs`) | 27018 |
| `db_shard_2` | Шард 2 (`mongod`, `--shardsvr`, rs `shard2rs`) | 27018 |
| `db_router`  | Роутер (`mongos`)                              | 27017 |
| `api`        | API (`kazhem/pymongo_api:1.0.0`)               | 8080  |

## Как запустить

Выполнить:

```shell
docker compose up -d   # или: podman compose up -d
```

Как все запустится выполнить:

```shell
./scripts/init.sh
```

## Как проверить

- Приложение: <http://localhost:8080>. В ответе JSON:
  - `collections.helloDoc.documents_count >= 1000` (общее количество документов);
  - `shards` перечисляет оба шарда.
- Количество документов в каждом шарде:

  ```shell
  ./scripts/check.sh
  ```

## Как очистить ресурсы после проверки

```shell
docker compose down -v   # или: podman compose down -v
```
