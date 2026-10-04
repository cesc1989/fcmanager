# This seeds file should create the database records required to run the app.
#
# The code should be idempotent so that it can be executed at any time.
#
# To load the seeds, run `hanami db seed`. Seeds are also loaded as part of `hanami db prepare`.

# Traits agrupados por su `kind` (0 físicos, 1 mentales, 2 técnicos, 3 porteros).
# El seed es idempotente: el `name` tiene índice único y se hace upsert por él.
TRAITS_BY_KIND = {
  0 => %w[
    Aceleración
    Agilidad
    Equilibrio
    Salto
    Reacciones
    Velocidad
    Resistencia
    Fuerza
  ],
  1 => %w[
    Agresividad
    Compostura
    Intercepciones
    Posicionamiento
    Visión
  ],
  2 => [
    "Control de Balón",
    "Centros",
    "Efecto",
    "Marcaje",
    "Regate",
    "Tiros Libres",
    "Definición",
    "Remate de Cabeza",
    "Pase Largo",
    "Tiro Lejano",
    "Penaltis",
    "Pase Corto",
    "Potencia de Tiro",
    "Entrada Agresiva",
    "Entrada Normal",
    "Voleas"
  ],
  3 => %w[
    Estirada
    Parada
    Saque
    Reflejos
    Colocación
  ]
}.freeze

traits = Hanami.app["relations.traits"]

TRAITS_BY_KIND.each do |kind, names|
  names.each do |name|
    traits.upsert(
      {name: name, kind: kind},
      {target: :name, update: {kind: kind}}
    )
  end
end
