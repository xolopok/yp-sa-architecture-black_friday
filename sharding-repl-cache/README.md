# Мобильный мир: шардирование, репликация и кэширование

![Диаграмма](../docs/architecture/stage3.png)

## Состав

| Контейнер         | Тип                                                      | Порт  |
|-------------------|----------------------------------------------------------|-------|
| `db_cfg_1..3`     | Конфиг (`mongod`, `--configsvr`, rs `cfgrs`, 3 реплики)  | 27019 |
| `db_shard_1_1..3` | Шард 1 (`mongod`, `--shardsvr`, rs `shard1rs`, 3 реплики)| 27018 |
| `db_shard_2_1..3` | Шард 2 (`mongod`, `--shardsvr`, rs `shard2rs`, 3 реплики)| 27018 |
| `db_router`       | Роутер (`mongos`)                                        | 27017 |
| `cache`           | Кэш (`redis`)                                            | 6379  |
| `api`             | API (`kazhem/pymongo_api:1.0.0`)                         | 8080  |

Кэширование включается переменной окружения `REDIS_URL=redis://cache:6379` у сервиса `api`.

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
  - `shards` перечисляет оба шарда, хост каждого содержит по 3 реплики;
  - `cache_enabled: true`.
- Количество документов в каждом шарде и состав реплик:

  ```shell
  ./scripts/check.sh
  ```

- Скорость повторных запросов к эндпоинту `/helloDoc/users`:

  ```shell
  curl -s -o /dev/null -w "1-й запрос: %{time_total}s\n" http://localhost:8080/helloDoc/users
  curl -s -o /dev/null -w "2-й запрос: %{time_total}s\n" http://localhost:8080/helloDoc/users
  curl -s -o /dev/null -w "3-й запрос: %{time_total}s\n" http://localhost:8080/helloDoc/users
  ```

## Как очистить ресурсы после проверки

```shell
docker compose down -v   # или: podman compose down -v
```
