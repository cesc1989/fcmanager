# Contenedor Docker de fcmanager

Cómo corre fcmanager en el PC casero `coshinema` (Linux Mint, x86_64) y cómo operarlo.
Se puso en marcha el 2026-11-26 (plan: `docs/plans/2026-11-26-docker.md`, PR #1).

En el Mac se sigue desarrollando con `bin/dev`; nada de esto cambia el flujo de desarrollo.

## Resumen

```
 celular / tablet / Mac
          |
          |  http://<ip-de-coshinema>:2300
          v
 +------------------------- coshinema (host) --------------------------+
 |                                                                     |
 |  Docker Engine (systemd, arranca al prender)                        |
 |   +-------------- contenedor "fcmanager" ------------------------+  |
 |   |  bin/docker-entrypoint                                       |  |
 |   |    1. bundle exec hanami db prepare                          |  |
 |   |    2. exec bundle exec puma -C config/puma.rb  (:2300)       |  |
 |   |                                                              |  |
 |   |  /app/db  <------------- volumen ------------->  ./db        |  |
 |   +--------------------------------------------------------------+  |
 |                                        repo clonado: ./db/fcmanager.sqlite
 +---------------------------------------------------------------------+
```

- Un solo servicio (`web`) definido en `compose.yml`, con el contenedor llamado `fcmanager`.
- Puerto 2300 del host al 2300 del contenedor.
- La base SQLite vive en el host, en `db/fcmanager.sqlite` de la carpeta del repo, y se monta en `/app/db`.
- `restart: unless-stopped`: Docker lo vuelve a levantar después de un reinicio o una caída, salvo que se haya detenido a mano.
- No hace falta iniciar sesión en el PC para que la app responda.

## Archivos

| Archivo | Qué hace |
| --- | --- |
| `Dockerfile` | Imagen en dos etapas: `build` (gemas + assets) y la final (solo lo necesario para correr). |
| `.dockerignore` | Deja fuera `.git`, `node_modules`, assets ya compilados, bases `.sqlite`, logs y `tmp`. |
| `bin/docker-entrypoint` | Corre `hanami db prepare` y luego hace `exec` del comando (puma). |
| `compose.yml` | Servicio `web`: build, nombre, puerto, volumen y política de reinicio. |

## La imagen

### Etapa `base`

- `ruby:3.4.8-slim` (Debian). La versión debe coincidir con `.ruby-version` y `mise.toml`.
- Instala Bundler `4.1.0`, que debe coincidir con `BUNDLED WITH` de `Gemfile.lock`. La imagen de Ruby trae otro Bundler.
- Variables de entorno (las heredan las dos etapas siguientes):

| Variable | Valor | Por qué |
| --- | --- | --- |
| `HANAMI_ENV` | `production` | Sin recarga de código, logs en JSON. |
| `HANAMI_SERVE_ASSETS` | `true` | En producción Hanami no sirve `/assets` a menos que se le pida. Sin esto la página sale sin estilos. |
| `DATABASE_URL` | `sqlite://db/fcmanager.sqlite` | En producción no se lee `.env` (`dotenv` solo está en development/test). |
| `BUNDLE_WITHOUT` | `development:test` | No se excluye el grupo `cli`: ahí está `hanami-reloader`, que la CLI de Hanami espera. |
| `BUNDLE_DEPLOYMENT` | `1` | Instala exactamente lo del `Gemfile.lock`. |
| `BUNDLE_PATH` | `/usr/local/bundle` | Lugar de las gemas, se copia tal cual a la imagen final. |

### Etapa `build`

- Instala `build-essential` para compilar gemas nativas (`sqlite3`, `puma`, etc.).
- Copia Node 22 desde `node:22-slim`. El paquete npm `hanami-assets` exige node >= 22 y el de Debian es más viejo.
- `bundle install`, `npm ci` y `hanami assets compile` (esbuild), que genera `public/assets/` y `public/assets.json`.
- Borra `node_modules` al terminar. Node no llega a la imagen final.

### Imagen final

- Parte de `base`, agrega el paquete apt `sqlite3`. `hanami db prepare` usa esa CLI para cargar y volcar `config/db/structure.sql`; también sirve para consultar la base a mano.
- Usuario `app` con **uid 1000**, igual al primer usuario de Linux Mint, que es el dueño de `db/` en el host. Si no coinciden, SQLite responde "attempt to write a readonly database".
- Copia las gemas y la app ya compilada desde `build`.
- Pesa unos 213 MB.

## Arranque del contenedor

`bin/docker-entrypoint` corre siempre antes de puma:

1. `hanami db prepare`: crea la base si no existe, aplica migraciones pendientes y carga `config/db/seeds.rb`. Los seeds son idempotentes (upsert por `name`), así que correrlos en cada arranque no duplica nada.
2. `exec bundle exec puma -C config/puma.rb`: puma queda como PID 1 y escucha en `0.0.0.0:2300` (definido en `config/puma.rb`).

Efecto práctico: **las migraciones nuevas se aplican solas** al reconstruir y levantar el contenedor.

`db prepare` también vuelca `config/db/structure.sql`, pero dentro del contenedor (ese archivo no está montado), así que no ensucia el repo del host.

## Operación diaria en `coshinema`

Todos los comandos se corren desde la carpeta donde está clonado fcmanager.

| Tarea | Comando |
| --- | --- |
| Actualizar a lo último de `main` | `git pull && docker compose up -d --build` |
| Ver estado | `docker compose ps` |
| Ver logs | `docker compose logs -f` (Ctrl-C para salir) |
| Reiniciar | `docker compose restart` |
| Detener (no vuelve al reiniciar el PC) | `docker compose down` |
| Volver a levantar | `docker compose up -d` |
| Consola de Hanami | `docker exec -it fcmanager bundle exec hanami console` |
| Consola SQLite | `docker exec -it fcmanager sqlite3 db/fcmanager.sqlite` |
| Correr migraciones a mano | `docker exec fcmanager bundle exec hanami db migrate` |
| Shell dentro del contenedor | `docker exec -it fcmanager sh` |
| Limpiar imágenes viejas | `docker image prune` |

Para abrir la app desde otro dispositivo: `http://<ip-de-coshinema>:2300` (la IP sale con `hostname -I`). `coshinema` también está en Tailscale, así que desde un dispositivo de la misma tailnet sirve `http://coshinema:2300`.

**No correr `bin/dev` en `coshinema`** mientras el contenedor esté arriba: usan el mismo puerto y escribirían en la misma base.

## Datos, backup y restauración

La única fuente de verdad es `db/fcmanager.sqlite` en el host. La imagen no guarda datos: se puede borrar y reconstruir sin perder nada.

Backup (seguro con la app corriendo, usa la API de backup de SQLite):

```bash
sqlite3 db/fcmanager.sqlite ".backup $HOME/fcmanager-backup-$(date +%F).sqlite"
```

Sin `sqlite3` en el host, desde el contenedor:

```bash
docker exec fcmanager sqlite3 db/fcmanager.sqlite ".backup db/backup-$(date +%F).sqlite"
```

Restaurar:

```bash
docker compose down
cp ~/fcmanager-backup-AAAA-MM-DD.sqlite db/fcmanager.sqlite
docker compose up -d
```

El primer backup antes de pasar al contenedor quedó en `~/fcmanager-backup-2026-11-26.sqlite`.

## Probar la imagen en el Mac

Nunca con el puerto 2300 del host (lo usa `bin/dev`). Usar otro, por ejemplo 2399, y una copia de la base:

```bash
docker build --platform linux/amd64 -t fcmanager .
mkdir -p tmp/docker-db && cp db/fcmanager.sqlite tmp/docker-db/
docker run -d --name fcmanager-check --platform linux/amd64 \
  -p 2399:2300 -v "$PWD/tmp/docker-db:/app/db" fcmanager

curl -s -o /dev/null -w "%{http_code}\n" http://localhost:2399/

docker rm -f fcmanager-check && rm -rf tmp/docker-db
```

`--platform linux/amd64` hace que la imagen sea igual a la de `coshinema` (x86_64), aunque el Mac sea arm64. Es más lento por la emulación.

## Problemas conocidos y qué revisar

| Síntoma | Causa probable | Qué hacer |
| --- | --- | --- |
| `port is already allocated` al levantar | Algo más usa el 2300, casi siempre `bin/dev` | `ss -ltnp \| grep 2300`, detener ese proceso. |
| "attempt to write a readonly database" | `db/` o el `.sqlite` no son del uid 1000 | `stat -c '%u %n' db db/fcmanager.sqlite`; corregir con `sudo chown -R 1000:1000 db`. |
| La página carga sin estilos | Falta `HANAMI_SERVE_ASSETS=true` o los assets no se compilaron | Revisar el `Dockerfile`; el CSS (`/assets/app-*.css`) debe responder `200 text/css`. |
| El contenedor se reinicia en bucle | Falló `db prepare` (migración rota, base corrupta) | `docker compose logs` muestra el error antes de puma. |
| No vuelve después de reiniciar el PC | Docker no está habilitado en systemd, o se hizo `docker compose down` | `systemctl is-enabled docker` debe decir `enabled`; luego `docker compose up -d`. |
| Falla `bundle install` en el build por Bundler | Cambió `BUNDLED WITH` en `Gemfile.lock` | Actualizar la versión en `gem install bundler -v ...` del `Dockerfile`. |
| Error de versión de Ruby en el build | Cambió `.ruby-version` / `mise.toml` | Actualizar `ARG RUBY_VERSION` del `Dockerfile`. |

## Al cambiar el proyecto, revisar

- **Versión de Ruby o Bundler**: actualizar `ARG RUBY_VERSION` y `gem install bundler -v` en el `Dockerfile`.
- **Gema nueva con extensión nativa que necesita librerías del sistema**: agregar el paquete `-dev` en la etapa `build` y la librería en la imagen final.
- **Nueva variable de entorno**: en producción no se lee `.env`; agregarla en `ENV` del `Dockerfile` o en `environment:` de `compose.yml`.
- **Nuevo archivo que no debe ir en la imagen** (bases, secretos, archivos grandes): agregarlo a `.dockerignore`.
- **Seeds**: deben seguir siendo idempotentes, porque corren en cada arranque.

## Pendiente (fuera de alcance del plan original)

- Backup automático diario (cron con `sqlite3 ... ".backup ..."`).
- IP fija para `coshinema` reservada en el router.
- Construir la imagen en el Mac y publicarla en un registro, en vez de `--build` en `coshinema`.
