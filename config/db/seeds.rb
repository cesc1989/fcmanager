# frozen_string_literal: true

# This seeds file should create the database records required to run the app.
#
# The code should be idempotent so that it can be executed at any time.
#
# To load the seeds, run `hanami db seed`. Seeds are also loaded as part of `hanami db prepare`.

# Traits del FC26 agrupados por su `kind` (0 físicos, 1 mentales, 2 técnicos, 3 arquería).
# El seed es idempotente: el `name` tiene índice único y se hace upsert por él.
TRAITS_BY_KIND = {
  0 => %w[
    Aceleración
    Agilidad
    Balance
    Energía
    Fuerza
    Salto
    Sprint
  ],
  1 => [
    "Agresividad",
    "Compostura",
    "Intercepción",
    "Posición Ataque",
    "Reacciones",
    "Visión"
  ],
  2 => [
    "Barridas",
    "Cabeceo",
    "Centros",
    "Control Balón",
    "Curva",
    "Definición",
    "Entradas",
    "Fuerza Tiro",
    "Pase Corto",
    "Pase Largo",
    "Penales",
    "Percepción Defensiva",
    "Precisión TL",
    "Regates",
    "Tiros Largos",
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

# Renombres del catálogo anterior al del FC26. Se aplican in-place (mismo `id`)
# para conservar los `player_traits` existentes. Si el nombre viejo no existe
# (BD desde cero) es no-op. Nada se borra.
TRAIT_RENAMES = {
  "Equilibrio" => ["Balance", 0],
  "Velocidad" => ["Sprint", 0],
  "Resistencia" => ["Energía", 0],
  "Reacciones" => ["Reacciones", 1],
  "Intercepciones" => ["Intercepción", 1],
  "Posicionamiento" => ["Posición Ataque", 1],
  "Control de Balón" => ["Control Balón", 2],
  "Efecto" => ["Curva", 2],
  "Marcaje" => ["Percepción Defensiva", 2],
  "Regate" => ["Regates", 2],
  "Tiros Libres" => ["Precisión TL", 2],
  "Remate de Cabeza" => ["Cabeceo", 2],
  "Tiro Lejano" => ["Tiros Largos", 2],
  "Penaltis" => ["Penales", 2],
  "Potencia de Tiro" => ["Fuerza Tiro", 2],
  "Entrada Agresiva" => ["Barridas", 2],
  "Entrada Normal" => ["Entradas", 2]
}.freeze

traits = Hanami.app["relations.traits"]

TRAIT_RENAMES.each do |old_name, (new_name, kind)|
  next unless traits.where(name: old_name).exist?
  next if old_name != new_name && traits.where(name: new_name).exist?

  traits.where(name: old_name).update(name: new_name, kind: kind)
end

TRAITS_BY_KIND.each do |kind, names|
  names.each do |name|
    traits.upsert(
      {name: name, kind: kind},
      {target: :name, update: {kind: kind}}
    )
  end
end

# Clubes que la app busca por nombre (ver app/repos/club_repo.rb).
CLUBS = ["Grimsby Town", "Agente Libre"].freeze

clubs = Hanami.app["relations.clubs"]

CLUBS.each do |name|
  clubs.insert(name: name) unless clubs.where(name: name).exist?
end
