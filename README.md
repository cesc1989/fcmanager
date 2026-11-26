# FC Manager

Gestor de plantilla para el FC 26 (o cualquier FC en realidad).

Me encuentro muchas veces queriendo comparar o revisando la plantilla. Para hacerlo sin tener que abrir el juego puedo venir a FC Manager, cargar la lista de jugadores (manualmente), asignar valores a un grupo selecto de atributos, organizar la formación, compararlos y más.

Todo sin tener que navegar la UI incomoda de FC y sin prender la consola.

## Colaborar

- Set up the project with `bin/setup`
- Run the server with `bin/dev`
- View the app at [http://localhost:2300](http://localhost:2300)
- Run the tests with `bundle exec rake`


## Correr en casa con Docker

En el PC que sirve la app (Linux, con Docker Engine y el plugin compose):

- Primera vez o después de actualizar: `git pull && docker compose up -d --build`
- Abrir desde cualquier dispositivo de la casa: `http://<ip-del-pc>:2300`
- Logs: `docker compose logs -f`
- Detener: `docker compose down`

La base es `db/fcmanager.sqlite` del host (montada como volumen). Las migraciones
y seeds corren solos al arrancar el contenedor. Para un backup basta copiar ese archivo.

No correr `bin/dev` en ese PC mientras el contenedor esté arriba: usan el mismo
puerto y la misma base.
