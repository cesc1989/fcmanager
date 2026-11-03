# Página Formación Plan de Implementación

> **Para trabajadores agénticos:** SUB-HABILIDAD REQUERIDA: Usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para implementar este plan tarea por tarea. Los pasos usan casillas de verificación (`- [ ]`) para el seguimiento.

**Objetivo:** Traer la pestaña "Formación" del prototipo a fcmanager: un campo 1-4-1-4-1 con 11 huecos donde se coloca el once del club, guardado en la base de datos.

**Arquitectura:** El once vive en una tabla nueva `lineup_slots` (un registro por hueco ocupado) y la formación del club en una columna nueva `clubs.formation`. Dos objetos Ruby puros en `lib/fcmanager/` hacen el trabajo: `Formation` (catálogo de huecos y encaje jugador/hueco) y `Lineup` (el once inmutable: asignar con intercambio, sacar, vaciar, auto). `LineupRepo` carga y guarda un `Lineup`. La página se renderiza en el servidor (`GET /formation`); cada cambio es un `POST` que redirige a `/formation`. Arrastrar y soltar rellena un form oculto y lo envía.

**Stack Tecnológico:** Hanami 3.0.2, ROM/Sequel + SQLite, ERB, esbuild (`hanami-assets`), RSpec + Rack::Test, Ruby 3.4.

**Especificación:** Prototipo en `~/projects/devaspros-projects/prototipos/careermode-manager`: sección **Formación (1-4-1-4-1)** de su `README.md`, `index.html` (sección FORMACIÓN), `js/pitch.js`, `js/playerlist.js`, `js/store.js` (`slotOf`, `assign`, `clearSlot`, `benchPlayer`, `clearLineup`, `autoFill`), `CM.FORMATION` en `js/data.js:86` y el bloque `/* ===== Formación ===== */` de `css/styles.css` (líneas ~193–331). Decisiones tomadas con el usuario (2026-11-03) que **reemplazan** al prototipo:

1. El once se guarda en una tabla (`lineup_slots`), no en `localStorage`.
2. Formación fija 1-4-1-4-1 por ahora, pero con columna `clubs.formation` (enum entero, `"4-1-4-1" => 0`) para poder añadir más.
3. Arrastrar y soltar envía un form oculto (POST normal + redirect), igual de simple que el resto de la app.

Por qué `formation` va en `clubs` y no en `lineup_slots`: es un dato del club (una formación activa), no de cada hueco; en `lineup_slots` se repetiría en 11 filas y podría quedar inconsistente.

## Restricciones Globales

- Namespace Ruby `Fcmanager` (c minúscula). Dominio nuevo en `lib/fcmanager/` (autoload Zeitwerk, como `compare_pair.rb`).
- Enums: columna **integer** en la DB + `read: Types::String.enum(...)` en la relación (ver `app/relations/players.rb`).
- Migraciones en `config/db/migrate` como bloques `ROM::SQL.migration`; regenerar `config/db/structure.sql` (lo hace `bundle exec hanami db migrate`).
- Solo cuentan los jugadores de la plantilla: club "Grimsby Town" (`club_repo.grimsby_town`, `player_repo.all`). Ids de otros clubes se ignoran en todo POST y en `?sel=`.
- `players.age` y `players.overall` son `string` en la DB: `to_i` antes de ordenar o promediar.
- Posiciones con las claves del proyecto (`po dfi dfc dfd mcd mi mc mco md ei ed dc`), **no** las del prototipo (`LI`/`LD` → `dfi`/`dfd`). La línea POR/DEF/MED/DEL sale de `PlayersCatalog.group_of`.
- Huecos de la 1-4-1-4-1 (key, etiqueta, posición, x, y, db), copiados de `CM.FORMATION`:
  `gk POR po 50 90 0` · `lb DFI dfi 12 71 1` · `cbl DFC dfc 36 77 2` · `cbr DFC dfc 64 77 3` · `rb DFD dfd 88 71 4` · `cdm MCD mcd 50 57 5` · `lm MI mi 12 36 6` · `cml MC mc 37 41 7` · `cmr MC mc 63 41 8` · `rm MD md 88 36 9` · `st DC dc 50 15 10`.
- Escala de color: helper `rating_class` (`is-elite` ≥80, `is-good` ≥74, `is-mid` ≥67, `is-low`).
- Textos en español tal cual el prototipo: "Jugadores", "Auto", "Vaciar", "Formación", "N/11 alineados", "Media N", "Arrastra un jugador a una posición del campo, o haz clic para seleccionarlo y luego clic en el hueco.", "¿Vaciar la alineación actual?", "Quitar del campo", "En el once · DFC", "Fuera del once", "XI", "<Nombre> juega de <Posición> · hueco de <Posición>".
- No hay CSRF ni sesiones en la app: los forms POST no llevan token.
- Puerto 2300 (para revisiones manuales con otro servidor, usar puma en otro puerto). Tests: `bundle exec rspec`. Lint: `bundle exec rubocop` sobre archivos nuevos.
- Specs: todo dentro del `it`, four-phase (setup / exercise / verify), sin `let`/`before`, como `spec/requests/squad_release_spec.rb`.

## Enfoque de Revisión

1. **Ids basura o ajenos** en `player_id` (`abc`, vacío, `012`, inexistente, de "Agente Libre") o en `?sel=` → 302 a `/formation` sin cambiar nada; `?sel=` inválido se ignora (200, nada seleccionado). Prueba: Tarea 2.1 (`Lineup`), Tarea 4.1 (`sel`) y Tarea 5.1 (POST).
2. **Hueco inexistente** (`slot=zz`, `slot=`) → nada cambia. Prueba: Tarea 2.1 y Tarea 5.1.
3. **Jugador liberado estando en el once** → se borra su fila de `lineup_slots` y no aparece en el campo ni en el recuento. Prueba: Tarea 3.1.
4. **`overall` como string** (`"9"` vs `"10"`) → Auto elige al de 10 y la media es numérica. Prueba: Tarea 2.1.
5. **Mover un jugador del campo a otro hueco ocupado o a su propio hueco** → intercambio sin duplicados (el índice único sobre `player_id` no debe saltar). Prueba: Tarea 2.1 y Tarea 5.1.

---

## Etapa 1 — Base (tareas independientes)

> Hecha el 2026-11-03. Notas de la ejecución: las relaciones usadas directamente (`Hanami.app["relations.x"]`) devuelven **hashes**, no structs, así que en los specs se lee `row[:slot]`; dentro de un repo sí son structs. Se añadió un spec que comprueba que los `db` de `Formation` coinciden con el enum de `lineup_slots`.

### Tarea 1.1: Tablas `clubs.formation` y `lineup_slots` + relaciones

**Archivos:**
- Crear: `config/db/migrate/20261103120000_add_formation_to_clubs.rb`
- Crear: `config/db/migrate/20261103120100_create_lineup_slots.rb`
- Crear: `app/relations/lineup_slots.rb`
- Modificar: `app/relations/clubs.rb`
- Modificar: `config/db/structure.sql` (regenerado)
- Crear: `spec/relations/lineup_slots_spec.rb`

**Migraciones:**

```ruby
# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :clubs do
      # Enum: 0 = "4-1-4-1" (ver app/relations/clubs.rb y Fcmanager::Formation).
      add_column :formation, Integer, null: false, default: 0
    end
  end
end
```

```ruby
# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :lineup_slots do
      primary_key :id

      foreign_key :club_id, :clubs, null: false, on_delete: :cascade
      foreign_key :player_id, :players, null: false, on_delete: :cascade
      # Enum: hueco de la formación (ver app/relations/lineup_slots.rb).
      column :slot, Integer, null: false

      index %i[club_id slot], unique: true
      index :player_id, unique: true
    end
  end
end
```

**Relación nueva:**

```ruby
# frozen_string_literal: true

module Fcmanager
  module Relations
    class LineupSlots < Fcmanager::DB::Relation
      schema :lineup_slots, infer: true do
        associations do
          belongs_to :club
          belongs_to :player
        end

        # Claves de los huecos de Fcmanager::Formation. Si se añade otra
        # formación, sus huecos necesitan claves y enteros nuevos aquí.
        attribute(
          :slot,
          Types::Integer,
          read: Types::String.enum(
            "gk" => 0,
            "lb" => 1,
            "cbl" => 2,
            "cbr" => 3,
            "rb" => 4,
            "cdm" => 5,
            "lm" => 6,
            "cml" => 7,
            "cmr" => 8,
            "rm" => 9,
            "st" => 10
          )
        )
      end
    end
  end
end
```

**`app/relations/clubs.rb`** queda:

```ruby
      schema :clubs, infer: true do
        associations do
          has_many :players
          has_many :lineup_slots
        end

        attribute(
          :formation,
          Types::Integer,
          read: Types::String.enum(
            "4-1-4-1" => 0
          )
        )
      end
```

**Pasos:**

- [ ] Escribir el spec:

```ruby
# frozen_string_literal: true

RSpec.describe "Relación lineup_slots", :db do
  it "expone el hueco como clave y la formación del club como string" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    club_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Portero",
      age: "30",
      overall: "75",
      role: 4,
      height: "190",
      dominant_foot: 0,
      primary_position: 0,
      club_id: club_id
    )

    lineup_slots.insert(club_id: club_id, player_id: player_id, slot: 10)

    expect(lineup_slots.where(club_id: club_id).one.slot).to eq("st")
    expect(clubs.by_pk(club_id).one.formation).to eq("4-1-4-1")
  end

  it "no deja al mismo jugador en dos huecos" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    club_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Central",
      age: "26",
      overall: "74",
      role: 3,
      height: "186",
      dominant_foot: 0,
      primary_position: 2,
      club_id: club_id
    )
    lineup_slots.insert(club_id: club_id, player_id: player_id, slot: 2)

    insert_twice = -> { lineup_slots.insert(club_id: club_id, player_id: player_id, slot: 3) }

    expect(&insert_twice).to raise_error(Sequel::UniqueConstraintViolation)
  end
end
```

- [ ] `bundle exec hanami db migrate` (si la BD de test no se migra sola: `HANAMI_ENV=test bundle exec hanami db migrate`). Revisar el diff de `config/db/structure.sql`.
- [ ] `bundle exec rspec spec/relations/lineup_slots_spec.rb` → pasa. `bundle exec rake` completo (los specs existentes insertan clubes solo con `name`; el `default: 0` los cubre).

---

### Tarea 1.2: `Formation`

Catálogo de formaciones (una por ahora) y encaje de un jugador en un hueco.

**Archivos:**
- Crear: `lib/fcmanager/formation.rb`
- Crear: `spec/lib/fcmanager/formation_spec.rb`

**Interfaz:**

```ruby
# frozen_string_literal: true

module Fcmanager
  # Formaciones del equipo y sus huecos en el campo (port de `CM.FORMATION`).
  #
  # `clubs.formation` guarda la clave de la formación del club y
  # `lineup_slots.slot` el `db` de cada hueco.
  class Formation
    # `position`: clave de `players.primary_position`. `x`/`y`: % en el campo.
    Slot = Data.define(:key, :label, :position, :x, :y, :db)

    attr_reader :key, :name, :slots

    def initialize(key:, name:, slots:)
      @key = key
      @name = name
      @slots = slots.freeze
    end

    ALL = {
      "4-1-4-1" => new(
        key: "4-1-4-1",
        name: "1-4-1-4-1",
        slots: [
          Slot.new(key: "gk", label: "POR", position: "po", x: 50, y: 90, db: 0),
          Slot.new(key: "lb", label: "DFI", position: "dfi", x: 12, y: 71, db: 1),
          Slot.new(key: "cbl", label: "DFC", position: "dfc", x: 36, y: 77, db: 2),
          Slot.new(key: "cbr", label: "DFC", position: "dfc", x: 64, y: 77, db: 3),
          Slot.new(key: "rb", label: "DFD", position: "dfd", x: 88, y: 71, db: 4),
          Slot.new(key: "cdm", label: "MCD", position: "mcd", x: 50, y: 57, db: 5),
          Slot.new(key: "lm", label: "MI", position: "mi", x: 12, y: 36, db: 6),
          Slot.new(key: "cml", label: "MC", position: "mc", x: 37, y: 41, db: 7),
          Slot.new(key: "cmr", label: "MC", position: "mc", x: 63, y: 41, db: 8),
          Slot.new(key: "rm", label: "MD", position: "md", x: 88, y: 36, db: 9),
          Slot.new(key: "st", label: "DC", position: "dc", x: 50, y: 15, db: 10)
        ]
      )
    }.freeze

    DEFAULT_KEY = "4-1-4-1"

    # Clave desconocida o nil → la formación por defecto.
    def self.fetch(key)
      ALL.fetch(key.to_s) { ALL.fetch(DEFAULT_KEY) }
    end

    # Hueco por clave ("gk", "cbl", …) o nil.
    def slot(key)
      slots.find { |slot| slot.key == key.to_s }
    end

    def slot_keys
      slots.map(&:key)
    end

    def size
      slots.size
    end

    # :exact (misma posición), :line (misma línea POR/DEF/MED/DEL) u :off.
    def fit_of(position_key, slot)
      return :exact if position_key.to_s == slot.position
      return :line if PlayersCatalog.group_of(position_key) == PlayersCatalog.group_of(slot.position)

      :off
    end
  end
end
```

**Pasos:**

- [ ] Spec (sin DB):

```ruby
# frozen_string_literal: true

RSpec.describe Fcmanager::Formation do
  it "la 1-4-1-4-1 tiene los 11 huecos del prototipo en orden" do
    formation = described_class.fetch("4-1-4-1")

    keys = formation.slot_keys
    labels = formation.slots.map(&:label)

    expect(formation.name).to eq("1-4-1-4-1")
    expect(keys).to eq(%w[gk lb cbl cbr rb cdm lm cml cmr rm st])
    expect(labels).to eq(%w[POR DFI DFC DFC DFD MCD MI MC MC MD DC])
    expect(formation.slots.map(&:db)).to eq((0..10).to_a)
  end

  it "una clave desconocida o nil da la formación por defecto" do
    keys = ["3-5-2", nil]

    formations = keys.map { |key| described_class.fetch(key) }

    expect(formations.map(&:key)).to eq(%w[4-1-4-1 4-1-4-1])
  end

  it "clasifica el encaje: posición exacta, misma línea u otra línea" do
    formation = described_class.fetch("4-1-4-1")
    striker_slot = formation.slot("st")

    fits = %w[dc ei mco].map { |position| formation.fit_of(position, striker_slot) }

    expect(fits).to eq(%i[exact line off])
  end

  it "slot devuelve nil para claves que no existen" do
    formation = described_class.fetch("4-1-4-1")

    missing = formation.slot("zz")

    expect(missing).to be_nil
  end
end
```

- [ ] `bundle exec rspec spec/lib/fcmanager/formation_spec.rb` → falla; implementar; pasa.
- [ ] `bundle exec rubocop lib/fcmanager/formation.rb spec/lib/fcmanager/formation_spec.rb`.

---

### Tarea 1.3: Lista de jugadores compartida (refactor de Comparar)

Sacar la lista lateral de `compare/show.html.erb` a un parcial y su CSS a un archivo común, sin cambiar el HTML que genera Comparar.

**Archivos:**
- Crear: `app/templates/shared/_bench_list.html.erb`
- Modificar: `app/templates/compare/show.html.erb`
- Crear: `app/assets/css/bench.css`
- Modificar: `app/assets/css/compare.css`
- Modificar: `app/assets/js/app.js` (import)

**Parcial** (locals: `players`, `selected_id`, `href` y `badge`; los dos últimos son lambdas que reciben al jugador; `badge` devuelve el texto de la insignia o `nil`, y si hay insignia el jugador sale atenuado):

```erb
<% if players.empty? %>
  <p class="empty">
    Añade jugadores desde la pestaña Plantilla.
  </p>
<% end %>

<% grouped_squad(players).each do |group| %>
  <div class="bench-group">
    <%= group[:label] %>

    <span class="muted">
      <%= group[:players].size %>
    </span>
  </div>

  <% group[:players].each do |player| %>
    <% position = position_info(player.primary_position) %>
    <% mark = badge.call(player) %>

    <a href="<%= href.call(player) %>"
       class="bench-item <%= "is-on-pitch" if mark %> <%= "is-selected" if player.id == selected_id %>"
       draggable="true"
       data-player-id="<%= player.id %>"
    >
      <span class="pos-tag pos-<%= position[:group] %>"
            title="<%= position[:label] %>"
      >
        <%= position[:short] %>
      </span>

      <span class="bench-info">
        <span class="bench-name">
          <%= player.name %>
        </span>

        <span class="bench-sub">
          <%= player.age %> años · <%= role_label(player.role) %>
        </span>
      </span>

      <% if mark %>
        <span class="badge-xi">
          <%= mark %>
        </span>
      <% end %>

      <span class="ovr <%= rating_class(player.overall) %>">
        <%= player.overall %>
      </span>
    </a>
  <% end %>
<% end %>
```

**En `compare/show.html.erb`**, reemplazar todo el contenido de `<div class="bench-list">` por:

```erb
      <div class="bench-list">
        <%= render "shared/bench_list",
                   players: players,
                   selected_id: nil,
                   href: ->(player) { compare_path(pair.with(player.id)) },
                   badge: ->(player) { pair.box_of(player.id)&.to_s&.upcase } %>
      </div>
```

**CSS:** mover de `compare.css` a `bench.css` los bloques `.compare-layout` … `.bench-sub` (líneas 4–52) y la regla `@media (max-width: 900px)` del final. En `bench.css` el grid se comparte:

```css
/* Lista lateral de jugadores: Comparar y Formación. */
.compare-layout,
.formation-layout {
  display: grid;
  grid-template-columns: 340px minmax(0, 1fr);
  gap: 18px;
  align-items: start;
}

/* … .bench … .bench-sub tal cual … */

@media (max-width: 900px) {
  .compare-layout,
  .formation-layout { grid-template-columns: 1fr; }
  .bench { position: static; }
  .bench-list { max-height: 320px; }
}
```

En `app.js`, `import "../css/bench.css";` justo antes de `import "../css/compare.css";`.

**Pasos:**

- [ ] Hacer el refactor.
- [ ] `bundle exec rspec spec/requests/compare_spec.rb` → sigue verde sin tocar el spec.
- [ ] Revisar `/compare` en el navegador: misma apariencia, drag & drop sigue funcionando.

---

## Etapa 2 — Dominio del once (depende de la Tarea 1.2)

> Hecha el 2026-11-03. Se añadió un caso extra: `auto_fill` ignora a jugadores fuera de `squad_ids`.

### Tarea 2.1: `Lineup`

Port de la parte de alineación de `js/store.js`.

**Archivos:**
- Crear: `lib/fcmanager/lineup.rb`
- Crear: `spec/lib/fcmanager/lineup_spec.rb`

**Interfaz:**

```ruby
# frozen_string_literal: true

module Fcmanager
  # Once de un club: qué jugador (id) ocupa cada hueco de su formación.
  #
  # Es inmutable: cada operación devuelve un Lineup nuevo. Solo admite ids de
  # `squad_ids` (la plantilla); el resto se descarta en silencio.
  class Lineup
    attr_reader :formation, :squad_ids

    # "12" → 12; "abc", "", "3x", nil → nil. Base 10 ("012" → 12).
    def self.parse_id(value)
      Integer(value.to_s, 10, exception: false)
    end

    # `assignments`: {"gk" => 3, "st" => 9}. Descarta huecos que no son de la
    # formación, ids fuera de `squad_ids` y jugadores repetidos (gana el primer
    # hueco en el orden de la formación).
    def initialize(formation, assignments = {}, squad_ids:)
      @formation = formation
      @squad_ids = squad_ids.to_a
      @assignments = clean(assignments)
    end

    def to_h
      @assignments.dup
    end

    def player_in(slot_key)
      @assignments[slot_key.to_s]
    end

    def slot_of(player_id)
      @assignments.key(player_id)
    end

    def count
      @assignments.size
    end

    # Media redondeada del `overall` de los alineados, o nil si no hay ninguno.
    def average(players)
      overalls = players.select { |player| slot_of(player.id) }.map { |player| player.overall.to_i }
      return nil if overalls.empty?

      (overalls.sum.to_f / overalls.size).round
    end

    # Coloca al jugador en el hueco. Si venía de otro hueco, el ocupante pasa a
    # ese hueco (intercambio); si venía de la lista, el ocupante sale del once.
    def assign(slot_key, player_id)
      slot_key = slot_key.to_s
      return self unless formation.slot(slot_key) && squad_ids.include?(player_id)

      previous = slot_of(player_id)
      return self if previous == slot_key

      occupant = player_in(slot_key)
      changed = to_h.merge(slot_key => player_id)
      changed.delete(previous) if previous
      changed[previous] = occupant if previous && occupant

      with(changed)
    end

    def clear(slot_key)
      with(to_h.except(slot_key.to_s))
    end

    def bench(player_id)
      slot_key = slot_of(player_id)
      slot_key ? clear(slot_key) : self
    end

    def clear_all
      with({})
    end

    # Rellena los huecos vacíos por `overall` desc (empate: id asc): primero
    # con jugadores de la posición exacta y luego con los de la misma línea.
    def auto_fill(players)
      ranked = players
        .select { |player| squad_ids.include?(player.id) }
        .sort_by { |player| [-player.overall.to_i, player.id] }
      changed = to_h
      taken = changed.values

      %i[exact line].each do |pass|
        formation.slots.each do |slot|
          next if changed.key?(slot.key)

          pick = ranked.find { |player| !taken.include?(player.id) && fits?(player, slot, pass) }
          next unless pick

          changed[slot.key] = pick.id
          taken << pick.id
        end
      end

      with(changed)
    end

    private

    def fits?(player, slot, pass)
      fit = formation.fit_of(player.primary_position, slot)
      pass == :exact ? fit == :exact : fit != :off
    end

    def with(assignments)
      self.class.new(formation, assignments, squad_ids: squad_ids)
    end

    def clean(assignments)
      seen = []

      formation.slot_keys.each_with_object({}) do |key, acc|
        id = assignments[key] || assignments[key.to_sym]
        next unless id && squad_ids.include?(id) && !seen.include?(id)

        acc[key] = id
        seen << id
      end
    end
  end
end
```

**Pasos:**

- [ ] Spec (sin DB; los jugadores son `Data` locales con `id`, `primary_position` y `overall` como string):

```ruby
# frozen_string_literal: true

RSpec.describe Fcmanager::Lineup do
  it "descarta huecos desconocidos, ids fuera de la plantilla y repetidos" do
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    assignments = {"gk" => 1, "zz" => 2, "st" => 99, "cbl" => 3, "cbr" => 3}

    lineup = described_class.new(formation, assignments, squad_ids: [1, 2, 3])

    expect(lineup.to_h).to eq("gk" => 1, "cbl" => 3)
  end

  it "parse_id lee enteros en base 10 y devuelve nil con basura" do
    values = ["12", "012", "abc", "", "3x", nil]

    ids = values.map { |value| described_class.parse_id(value) }

    expect(ids).to eq([12, 12, nil, nil, nil, nil])
  end

  it "assign desde la lista coloca al jugador y saca al ocupante" do
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    lineup = described_class.new(formation, {"st" => 1}, squad_ids: [1, 2])

    result = lineup.assign("st", 2)

    expect(result.to_h).to eq("st" => 2)
    expect(lineup.to_h).to eq("st" => 1)
  end

  it "assign desde otro hueco intercambia con el ocupante" do
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    lineup = described_class.new(formation, {"cbl" => 1, "cbr" => 2}, squad_ids: [1, 2])

    result = lineup.assign("cbr", 1)

    expect(result.to_h).to eq("cbl" => 2, "cbr" => 1)
  end

  it "assign a un hueco vacío desde otro hueco deja libre el anterior" do
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    lineup = described_class.new(formation, {"cbl" => 1}, squad_ids: [1])

    result = lineup.assign("cbr", 1)

    expect(result.to_h).to eq("cbr" => 1)
  end

  it "assign ignora hueco desconocido, id ajeno, nil y el mismo hueco" do
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    lineup = described_class.new(formation, {"st" => 1}, squad_ids: [1, 2])

    results = [
      lineup.assign("zz", 2),
      lineup.assign("st", 99),
      lineup.assign("st", nil),
      lineup.assign("st", 1)
    ]

    expect(results.map(&:to_h)).to all(eq("st" => 1))
  end

  it "bench y clear sacan del once; clear_all lo vacía" do
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    lineup = described_class.new(formation, {"gk" => 1, "st" => 2}, squad_ids: [1, 2, 3])

    benched = lineup.bench(2)
    benched_outsider = lineup.bench(3)
    cleared = lineup.clear("gk")
    emptied = lineup.clear_all

    expect(benched.to_h).to eq("gk" => 1)
    expect(benched_outsider.to_h).to eq(lineup.to_h)
    expect(cleared.to_h).to eq("st" => 2)
    expect(emptied.count).to eq(0)
  end

  it "auto_fill usa posición exacta primero, luego la línea, por overall numérico" do
    player = Data.define(:id, :primary_position, :overall)
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    players = [
      player.new(id: 1, primary_position: "dc", overall: "9"),
      player.new(id: 2, primary_position: "dc", overall: "10"),
      player.new(id: 3, primary_position: "ei", overall: "90"),
      player.new(id: 4, primary_position: "po", overall: "70"),
      player.new(id: 5, primary_position: "mco", overall: "88")
    ]
    lineup = described_class.new(formation, {}, squad_ids: players.map(&:id))

    result = lineup.auto_fill(players)

    expect(result.player_in("st")).to eq(2)
    expect(result.player_in("gk")).to eq(4)
    expect(result.player_in("cdm")).to eq(5)
    expect(result.slot_of(3)).to be_nil
  end

  it "auto_fill respeta los huecos ya ocupados" do
    player = Data.define(:id, :primary_position, :overall)
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    players = [
      player.new(id: 1, primary_position: "dc", overall: "60"),
      player.new(id: 2, primary_position: "dc", overall: "90")
    ]
    lineup = described_class.new(formation, {"st" => 1}, squad_ids: [1, 2])

    result = lineup.auto_fill(players)

    expect(result.player_in("st")).to eq(1)
    expect(result.slot_of(2)).to be_nil
  end

  it "average redondea la media numérica de los alineados" do
    player = Data.define(:id, :primary_position, :overall)
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    players = [
      player.new(id: 1, primary_position: "po", overall: "9"),
      player.new(id: 2, primary_position: "dc", overall: "10"),
      player.new(id: 3, primary_position: "dc", overall: "99")
    ]
    lineup = described_class.new(formation, {"gk" => 1, "st" => 2}, squad_ids: [1, 2, 3])
    empty = described_class.new(formation, {}, squad_ids: [1, 2, 3])

    averages = [lineup.average(players), empty.average(players)]

    expect(averages).to eq([10, nil])
  end
end
```

Nota sobre el caso de `auto_fill`: en la primera pasada `mco` no es exacto para `cdm` (`mcd`); en la segunda sí encaja por línea (MED). `ei` (90) no entra en `st` porque en la primera pasada `st` ya lo ocupa el `dc` de 10; con un solo hueco DEL no queda sitio.

- [ ] `bundle exec rspec spec/lib/fcmanager/lineup_spec.rb` → falla; implementar; pasa.
- [ ] `bundle exec rubocop lib/fcmanager/lineup.rb spec/lib/fcmanager/lineup_spec.rb`.

---

## Etapa 3 — Persistencia (depende de las Tareas 1.1 y 2.1)

> Hecha el 2026-11-03. Corrección: en el primer caso del spec del repo, mover al portero a `st` intercambia con el delantero, así que el resultado esperado es `{"gk" => striker_id, "st" => keeper_id}`. Casos extra: el repo filtra por club y por plantilla, y `spec/repos/player_repo_spec.rb` cubre `squad_ids`.

### Tarea 3.1: `LineupRepo`, `squad_ids` y limpieza al liberar

**Archivos:**
- Crear: `app/repos/lineup_repo.rb`
- Modificar: `app/repos/player_repo.rb`
- Crear: `spec/repos/lineup_repo_spec.rb`
- Modificar: `spec/requests/squad_release_spec.rb`

**Repo:**

```ruby
# frozen_string_literal: true

module Fcmanager
  module Repos
    class LineupRepo < Fcmanager::DB::Repo
      # Once guardado del club, limitado a los jugadores de `squad_ids`.
      def for_club(club, squad_ids)
        formation = Formation.fetch(club[:formation])
        assignments = lineup_slots
          .where(club_id: club[:id])
          .to_a
          .to_h { |row| [row.slot, row.player_id] }

        Lineup.new(formation, assignments, squad_ids: squad_ids)
      end

      # Reemplaza el once guardado del club por `lineup`.
      def save(club, lineup)
        rows = lineup.to_h.map do |slot_key, player_id|
          {club_id: club[:id], slot: lineup.formation.slot(slot_key).db, player_id: player_id}
        end

        transaction do
          lineup_slots.where(club_id: club[:id]).delete
          lineup_slots.dataset.multi_insert(rows) unless rows.empty?
        end
      end

      # Carga el once, le aplica el bloque y guarda el resultado.
      def change(club, squad_ids)
        save(club, yield(for_club(club, squad_ids)))
      end
    end
  end
end
```

**`PlayerRepo`**: añadir `squad_ids` (lo usan las acciones que no necesitan cargar traits) y borrar el hueco al liberar:

```ruby
      # Ids de la plantilla, sin cargar traits.
      def squad_ids
        players.where(club_id: club_repo.grimsby_town[:id]).pluck(:id)
      end

      # Saca al jugador de la plantilla pasándolo al club "Agente Libre" y lo
      # quita del once.
      def release(id)
        transaction do
          lineup_slots.where(player_id: id).delete
          update(id, club_id: club_repo.free_agent[:id])
        end
      end
```

**Pasos:**

- [ ] Spec del repo:

```ruby
# frozen_string_literal: true

RSpec.describe Fcmanager::Repos::LineupRepo, :db do
  it "guarda y vuelve a cargar el once del club" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    repo = Hanami.app["repos.lineup_repo"]
    club_id = clubs.insert(name: "Grimsby Town")
    keeper_id = players.insert(
      name: "Portero",
      age: "30",
      overall: "75",
      role: 4,
      height: "190",
      dominant_foot: 0,
      primary_position: 0,
      club_id: club_id
    )
    striker_id = players.insert(
      name: "Delantero",
      age: "24",
      overall: "80",
      role: 4,
      height: "182",
      dominant_foot: 0,
      primary_position: 12,
      club_id: club_id
    )
    club = clubs.by_pk(club_id).one
    squad_ids = [keeper_id, striker_id]

    repo.change(club, squad_ids) { |lineup| lineup.assign("gk", keeper_id).assign("st", striker_id) }
    repo.change(club, squad_ids) { |lineup| lineup.assign("st", keeper_id) }
    reloaded = repo.for_club(club, squad_ids)

    expect(reloaded.to_h).to eq("gk" => striker_id, "st" => keeper_id)
    expect(reloaded.formation.name).to eq("1-4-1-4-1")
  end

  it "intercambiar dos jugadores del campo no viola el índice único" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    repo = Hanami.app["repos.lineup_repo"]
    club_id = clubs.insert(name: "Grimsby Town")
    left_id = players.insert(
      name: "Central Izq",
      age: "26",
      overall: "74",
      role: 3,
      height: "186",
      dominant_foot: 1,
      primary_position: 2,
      club_id: club_id
    )
    right_id = players.insert(
      name: "Central Der",
      age: "27",
      overall: "75",
      role: 3,
      height: "188",
      dominant_foot: 0,
      primary_position: 2,
      club_id: club_id
    )
    club = clubs.by_pk(club_id).one
    squad_ids = [left_id, right_id]
    repo.change(club, squad_ids) { |lineup| lineup.assign("cbl", left_id).assign("cbr", right_id) }

    repo.change(club, squad_ids) { |lineup| lineup.assign("cbr", left_id) }

    expect(repo.for_club(club, squad_ids).to_h).to eq("cbl" => right_id, "cbr" => left_id)
  end
end
```

- [ ] Añadir a `spec/requests/squad_release_spec.rb`:

```ruby
  it "al liberar a un jugador del once se borra su hueco" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Jugador Liberado",
      age: "25",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: player_id, slot: 10)

    patch("/squad/#{player_id}/release")

    expect(lineup_slots.where(player_id: player_id).count).to eq(0)
  end
```

- [ ] Rojo → implementar → verde. `bundle exec rake` completo.

---

## Etapa 4 — Página `/formation` en modo lectura (depende de las Etapas 1–3)

> Hecha el 2026-11-03. Cambios: el título del encaje usa coma ("juega de X, hueco de Y") en vez del punto medio; las clases de `.slot` y `.token` se arman sin espacios sobrantes; la cabecera del campo pasa a dos líneas en móvil (`flex-wrap`).

### Tarea 4.1: Ruta GET, acción, vista, plantillas, CSS y pestaña

Muestra la lista y el campo, la selección por `?sel=`, las fichas y los chips. Los botones y forms apuntan a rutas POST que se crean en la Tarea 5.1; aquí se declaran las cinco rutas para que `routes.path` funcione, pero las acciones POST llegan en la 5.1.

**Archivos:**
- Modificar: `config/routes.rb`
- Crear: `app/actions/formation/show.rb`
- Crear (esqueleto): `app/actions/formation/{assign,bench,auto,clear}.rb`
- Crear: `app/views/formation/show.rb`
- Crear: `app/templates/formation/show.html.erb`
- Crear: `app/templates/formation/_slot.html.erb`
- Crear: `app/templates/formation/_token.html.erb`
- Modificar: `app/views/helpers.rb`
- Modificar: `app/templates/layouts/app.html.erb`
- Crear: `app/assets/css/formation.css`
- Modificar: `app/assets/js/app.js` (solo el `import`)
- Crear: `spec/requests/formation_spec.rb`
- Modificar: `spec/requests/tabs_spec.rb`

**Rutas** (al final del bloque en `config/routes.rb`):

```ruby
    get "/formation", to: "formation.show", as: :formation
    post "/formation/assign", to: "formation.assign", as: :formation_assign
    post "/formation/bench", to: "formation.bench", as: :formation_bench
    post "/formation/auto", to: "formation.auto", as: :formation_auto
    post "/formation/clear", to: "formation.clear", as: :formation_clear
```

Hanami resuelve cada `to:` contra el contenedor de acciones, así que en esta tarea se crean también las cuatro acciones POST como esqueleto (`Assign`, `Bench`, `Auto`, `Clear` con `def handle(_request, response) = response.redirect_to(routes.path(:formation))`). La Tarea 5.1 las rellena.

**Acción:**

```ruby
# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      class Show < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(request, response)
          players = player_repo.all
          squad_ids = players.map(&:id)
          selected_id = Lineup.parse_id(request.params[:sel])

          response[:players] = players
          response[:lineup] = lineup_repo.for_club(club_repo.grimsby_town, squad_ids)
          response[:selected_id] = squad_ids.include?(selected_id) ? selected_id : nil
        end
      end
    end
  end
end
```

Ojo: dentro de `module Formation` (acciones), `Formation` a secas es el módulo de acciones. Si hace falta la clase de dominio, usar `Fcmanager::Formation`. Aquí no se usa.

**Vista:**

```ruby
# frozen_string_literal: true

module Fcmanager
  module Views
    module Formation
      class Show < Fcmanager::View
        expose :players, :lineup, :selected_id

        expose :players_by_id do |players|
          players.to_h { |player| [player.id, player] }
        end
      end
    end
  end
end
```

**Helpers** (en `app/views/helpers.rb`, junto a `compare_path`):

```ruby
      # Clic en la lista de Formación: selecciona al jugador o, si ya lo estaba,
      # lo deselecciona.
      def formation_select_path(player_id, selected_id)
        return routes.path(:formation) if player_id == selected_id

        routes.path(:formation, sel: player_id)
      end

      # Etiqueta del hueco que ocupa el jugador ("DFC") o nil.
      def lineup_badge(lineup, player_id)
        slot_key = lineup.slot_of(player_id)
        slot_key && lineup.formation.slot(slot_key).label
      end

      def fit_class(fit)
        {line: "fit-line", off: "fit-off"}.fetch(fit, "")
      end

      def fit_title(player, slot, fit)
        return player.name if fit == :exact

        "#{player.name} juega de #{position_info(player.primary_position)[:label]} · " \
          "hueco de #{position_info(slot.position)[:label]}"
      end
```

Y en `tab_class`, añadir la rama:

```ruby
                 when :formation then path.start_with?("/formation")
```

**Layout**: reemplazar el `<span class="tab is-disabled" …>Formación</span>` por:

```erb
        <a href="<%= routes.path(:formation) %>"
           class="<%= tab_class(:formation) %>"
        >
          Formación
        </a>
```

**Plantilla** `app/templates/formation/show.html.erb`:

```erb
<main>
  <section class="formation-layout">
    <aside class="bench">
      <div class="bench-head">
        <h2>
          Jugadores
        </h2>

        <div class="row-actions">
          <form method="post"
                action="<%= routes.path(:formation_auto) %>"
          >
            <button class="btn ghost sm"
                    type="submit"
            >
              Auto
            </button>
          </form>

          <button class="btn ghost sm"
                  type="button"
                  data-open-dialog="clear-lineup-dialog"
          >
            Vaciar
          </button>
        </div>
      </div>

      <p class="hint">
        Arrastra un jugador a una posición del campo, o haz clic para seleccionarlo y luego clic en el hueco.
      </p>

      <div class="bench-list"
           data-formation-bench
      >
        <%= render "shared/bench_list",
                   players: players,
                   selected_id: selected_id,
                   href: ->(player) { formation_select_path(player.id, selected_id) },
                   badge: ->(player) { lineup_badge(lineup, player.id) } %>
      </div>
    </aside>

    <div class="pitch-panel">
      <div class="pitch-head">
        <h2>
          Formación

          <strong>
            <%= lineup.formation.name %>
          </strong>
        </h2>

        <span class="spacer"></span>

        <span class="chip">
          <%= lineup.count %>/<%= lineup.formation.size %> alineados
        </span>

        <% average = lineup.average(players) %>

        <% if average %>
          <span class="chip">
            Media <%= average %>
          </span>
        <% end %>
      </div>

      <div class="pitch-outer">
        <div class="pitch">
          <div class="pitch-markings">
            <span class="line-mid"></span>

            <span class="circle-mid"></span>

            <span class="box box-top"></span>

            <span class="box-small box-small-top"></span>

            <span class="box box-bottom"></span>

            <span class="box-small box-small-bottom"></span>
          </div>

          <% lineup.formation.slots.each do |slot| %>
            <%= render "formation/slot",
                       slot: slot,
                       lineup: lineup,
                       player: players_by_id[lineup.player_in(slot.key)],
                       selected_id: selected_id %>
          <% end %>
        </div>
      </div>
    </div>
  </section>

  <form id="formation-drop-form"
        method="post"
        action="<%= routes.path(:formation_assign) %>"
        hidden
  >
    <input type="hidden" name="slot">

    <input type="hidden" name="player_id">
  </form>

  <form id="formation-bench-form"
        method="post"
        action="<%= routes.path(:formation_bench) %>"
        hidden
  >
    <input type="hidden" name="player_id">
  </form>

  <dialog id="clear-lineup-dialog"
          class="dialog"
  >
    <form method="post"
          action="<%= routes.path(:formation_clear) %>"
    >
      <p>
        ¿Vaciar la alineación actual?
      </p>

      <div class="dialog-actions">
        <button class="btn ghost"
                type="submit"
                formmethod="dialog"
                formnovalidate
        >
          Cancelar
        </button>

        <button class="btn danger"
                type="submit"
        >
          Vaciar
        </button>
      </div>
    </form>
  </dialog>
</main>
```

**Parcial `formation/_slot.html.erb`**: con un jugador seleccionado, todo el hueco es un botón que envía `assign`; si no, la ficha enlaza a la ficha del jugador y el × lo saca del campo.

```erb
<div class="slot <%= "is-empty" unless player %> <%= "is-target" if selected_id %>"
     style="left: <%= slot.x %>%; top: <%= slot.y %>%;"
     data-slot="<%= slot.key %>"
>
  <% if selected_id %>
    <form method="post"
          action="<%= routes.path(:formation_assign) %>"
    >
      <input type="hidden" name="slot" value="<%= slot.key %>">

      <input type="hidden" name="player_id" value="<%= selected_id %>">

      <button class="slot-target"
              type="submit"
              title="Colocar aquí"
      >
        <%= render "formation/token", slot: slot, lineup: lineup, player: player %>
      </button>
    </form>
  <% elsif player %>
    <a href="<%= routes.path(:squad_player, id: player.id) %>"
       class="token-link"
    >
      <%= render "formation/token", slot: slot, lineup: lineup, player: player %>
    </a>

    <form class="token-remove-form"
          method="post"
          action="<%= routes.path(:formation_bench) %>"
    >
      <input type="hidden" name="player_id" value="<%= player.id %>">

      <button class="token-remove"
              type="submit"
              title="Quitar del campo"
      >
        ×
      </button>
    </form>
  <% else %>
    <%= render "formation/token", slot: slot, lineup: lineup, player: nil %>
  <% end %>
</div>
```

**Parcial `formation/_token.html.erb`** (solo `<span>`, porque puede ir dentro de un `<button>`):

```erb
<% if player %>
  <% fit = lineup.formation.fit_of(player.primary_position, slot) %>

  <span class="token <%= rating_class(player.overall) %> <%= fit_class(fit) %>"
        title="<%= fit_title(player, slot, fit) %>"
        draggable="true"
        data-player-id="<%= player.id %>"
  >
    <span class="token-disc">
      <span class="token-ovr">
        <%= player.overall %>
      </span>

      <span class="token-pos">
        <%= position_info(player.primary_position)[:short] %>
      </span>
    </span>

    <span class="token-name">
      <%= player.name %>
    </span>
  </span>
<% else %>
  <span class="slot-empty">
    <span class="slot-label">
      <%= slot.label %>
    </span>
  </span>
<% end %>
```

**CSS** `app/assets/css/formation.css`: copiar del `css/styles.css` del prototipo desde `.pitch-panel` hasta `.token:hover .token-remove` (líneas ~244–331), **sin** `.formation-layout` (ya está en `bench.css`). Cambios y añadidos:

```css
/* Página Formación. Copiado del prototipo (css/styles.css). */

/* … bloque copiado … */

/* La ficha y el hueco son span/a/button en vez de div. */
.token-link { color: inherit; text-decoration: none; }
.slot form { margin: 0; }
.slot-target {
  all: unset;
  cursor: pointer;
  display: flex; flex-direction: column; align-items: center;
}

/* El × es un form hermano de la ficha; se muestra al pasar por el hueco. */
.token-remove-form { position: absolute; top: -6px; right: 6px; margin: 0; }
.token-remove { position: static; }
.slot:hover .token-remove { display: block; }

/* Ficha del jugador: "En el once · DFC". */
.card-line.ok { color: var(--accent); }
```

Quitar del bloque copiado `.token:hover .token-remove` (lo reemplaza `.slot:hover`) y las propiedades `position/top/right` de `.token-remove`.

En `app.js`, `import "../css/formation.css";` después de `compare.css`.

**Pasos:**

- [ ] Spec `spec/requests/formation_spec.rb`:

```ruby
# frozen_string_literal: true

RSpec.describe "Formation", :db, type: :request do
  it "lista la plantilla, pinta los 11 huecos vacíos y los chips" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    players.insert(
      name: "Theo Marchal",
      age: "27",
      overall: "83",
      role: 4,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    players.insert(
      name: "Fuera De Plantilla",
      age: "27",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: other_id
    )

    get("/formation")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Theo Marchal")
    expect(last_response.body).not_to include("Fuera De Plantilla")
    expect(last_response.body).to include("1-4-1-4-1")
    expect(last_response.body.scan(/data-slot="/).size).to eq(11)
    expect(last_response.body).to match(%r{0/11 alineados})
    expect(last_response.body).not_to include("Media")
  end

  it "muestra a los alineados en su hueco, con insignia, encaje y media" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    striker_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    winger_id = players.insert(
      name: "Eva Extremo",
      age: "22",
      overall: "71",
      role: 2,
      height: "170",
      dominant_foot: 1,
      primary_position: 11,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: striker_id, slot: 10)
    lineup_slots.insert(club_id: grimsby_id, player_id: winger_id, slot: 0)

    get("/formation")

    expect(last_response.body).to match(%r{2/11 alineados})
    expect(last_response.body).to include("Media 76")
    expect(last_response.body).to include(%(href="/squad/#{striker_id}"))
    expect(last_response.body).to match(/class="token is-mid fit-off"/)
    expect(last_response.body).to include("Eva Extremo juega de Extremo izquierdo · hueco de Portero")
  end

  it "con ?sel= marca al jugador y los huecos envían assign" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    get("/formation", sel: player_id.to_s)

    expect(last_response.body).to match(/class="bench-item\s+is-selected"/)
    expect(last_response.body.scan(/class="slot-target"/).size).to eq(11)
    expect(last_response.body).to include(%(name="player_id" value="#{player_id}"))
  end

  it "ignora un ?sel= basura o ajeno" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    outsider_id = players.insert(
      name: "Fuera De Plantilla",
      age: "27",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: other_id
    )

    bodies = ["abc", "", outsider_id.to_s].map { |sel| get("/formation", sel: sel).body }

    expect(bodies).to all(satisfy { |body| !body.include?("slot-target") })
  end
end
```

El parcial de la lista (Tarea 1.3) ya arma la clase con `compact.join(" ")`, así que sale `class="bench-item is-selected"` con un solo espacio.

- [ ] En `tabs_spec.rb`, añadir `formation_body = get("/formation").body` y las expectativas:

```ruby
    expect(formation_body).to match(%r{href="/formation"\s+class="tab is-active"})
    expect(squad_body).to match(%r{href="/formation"\s+class="tab"\s*>})
```

- [ ] Rojo → implementar → verde. `bundle exec rake` completo.
- [ ] Revisar `/formation` contra el prototipo (`python3 -m http.server 8080` en su carpeta, pestaña Formación), también con ancho de móvil.

---

## Etapa 5 — Cambios al once (depende de la Etapa 4; tareas independientes entre sí)

> 5.1 hecha el 2026-11-03. Cambio de texto: la ficha dice "En el once: DC" (dos puntos en vez del punto medio). El botón "Vaciar" solo abre su diálogo desde la Tarea 6.1, que añade el JS de `data-open-dialog`.

### Tarea 5.1: Acciones POST `assign`, `bench`, `auto`, `clear` y "Quitar del campo" en la ficha

**Archivos:**
- Modificar (rellenar los esqueletos de la 4.1): `app/actions/formation/{assign,bench,auto,clear}.rb`
- Modificar: `app/actions/squad/show.rb`, `app/views/squad/show.rb`, `app/templates/squad/show.html.erb`
- Crear: `spec/requests/formation_changes_spec.rb`
- Modificar: `spec/requests/squad_show_spec.rb`

**Acciones** (las cuatro siguen el mismo patrón):

```ruby
# frozen_string_literal: true

module Fcmanager
  module Actions
    module Formation
      class Assign < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(request, response)
          player_id = Lineup.parse_id(request.params[:player_id])

          lineup_repo.change(club_repo.grimsby_town, player_repo.squad_ids) do |lineup|
            lineup.assign(request.params[:slot], player_id)
          end

          response.redirect_to routes.path(:formation)
        end
      end
    end
  end
end
```

```ruby
      class Bench < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        # Solo se vuelve a la ficha de un jugador; cualquier otra cosa va a /formation.
        RETURN_TO = %r{\A/squad/\d+\z}

        def handle(request, response)
          player_id = Lineup.parse_id(request.params[:player_id])

          lineup_repo.change(club_repo.grimsby_town, player_repo.squad_ids) do |lineup|
            lineup.bench(player_id)
          end

          return_to = request.params[:return_to].to_s
          response.redirect_to(return_to.match?(RETURN_TO) ? return_to : routes.path(:formation))
        end
      end
```

```ruby
      class Auto < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(_request, response)
          players = player_repo.all

          lineup_repo.change(club_repo.grimsby_town, players.map(&:id)) do |lineup|
            lineup.auto_fill(players)
          end

          response.redirect_to routes.path(:formation)
        end
      end
```

```ruby
      class Clear < Fcmanager::Action
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(_request, response)
          lineup_repo.change(club_repo.grimsby_town, player_repo.squad_ids, &:clear_all)

          response.redirect_to routes.path(:formation)
        end
      end
```

**Ficha del jugador** (`squad/show`): la acción añade el once; la plantilla muestra dónde juega y el botón para sacarlo.

```ruby
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(request, response)
          player = player_repo.find_with_traits(request.params[:id])

          return response.redirect_to(routes.path(:squad)) unless player

          response[:player] = player
          response[:lineup] = lineup_repo.for_club(club_repo.grimsby_town, player_repo.squad_ids)
        end
```

Vista: `expose :player, :lineup`.

En `squad/show.html.erb`, al principio de `<section>`: `<% slot_key = lineup.slot_of(player.id) %>`. En `.row-actions`, después del enlace "Comparar":

```erb
        <% if slot_key %>
          <form method="post"
                action="<%= routes.path(:formation_bench) %>"
          >
            <input type="hidden" name="player_id" value="<%= player.id %>">

            <input type="hidden" name="return_to" value="<%= routes.path(:squad_player, id: player.id) %>">

            <button class="btn ghost sm danger"
                    type="submit"
            >
              Quitar del campo
            </button>
          </form>
        <% end %>
```

En `.card-meta`, después de la línea de altura y pie:

```erb
          <% if slot_key %>
            <div class="card-line ok">
              En el once · <%= lineup.formation.slot(slot_key).label %>
            </div>
          <% else %>
            <div class="card-line muted">
              Fuera del once
            </div>
          <% end %>
```

**Pasos:**

- [ ] Spec `spec/requests/formation_changes_spec.rb` (cada `it` crea su club y jugadores; se muestra la estructura de los casos, todos con el mismo setup inline de `formation_spec.rb`):

```ruby
# frozen_string_literal: true

RSpec.describe "Formation changes", :db, type: :request do
  it "assign coloca a un jugador de la lista y redirige" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )

    post("/formation/assign", slot: "st", player_id: player_id.to_s)

    expect(last_response.status).to eq(302)
    expect(last_response.headers["Location"]).to eq("/formation")
    expect(lineup_slots.where(club_id: grimsby_id).one[:slot]).to eq("st")
  end

  it "assign intercambia dos jugadores del campo" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    left_id = players.insert(
      name: "Central Izq",
      age: "26",
      overall: "74",
      role: 3,
      height: "186",
      dominant_foot: 1,
      primary_position: 2,
      club_id: grimsby_id
    )
    right_id = players.insert(
      name: "Central Der",
      age: "27",
      overall: "75",
      role: 3,
      height: "188",
      dominant_foot: 0,
      primary_position: 2,
      club_id: grimsby_id
    )
    lineup_slots.insert(club_id: grimsby_id, player_id: left_id, slot: 2)
    lineup_slots.insert(club_id: grimsby_id, player_id: right_id, slot: 3)

    post("/formation/assign", slot: "cbr", player_id: left_id.to_s)

    saved = lineup_slots.where(club_id: grimsby_id).to_a.to_h { |row| [row[:slot], row[:player_id]] }
    expect(saved).to eq("cbl" => right_id, "cbr" => left_id)
  end

  it "assign ignora ids basura, ajenos y huecos inexistentes" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    lineup_slots = Hanami.app["relations.lineup_slots"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    player_id = players.insert(
      name: "Ana Delantera",
      age: "24",
      overall: "80",
      role: 4,
      height: "175",
      dominant_foot: 0,
      primary_position: 12,
      club_id: grimsby_id
    )
    outsider_id = players.insert(
      name: "Fuera De Plantilla",
      age: "27",
      overall: "70",
      role: 0,
      height: "180",
      dominant_foot: 0,
      primary_position: 12,
      club_id: other_id
    )

    post("/formation/assign", slot: "st", player_id: "abc")
    post("/formation/assign", slot: "st", player_id: "")
    post("/formation/assign", slot: "st", player_id: outsider_id.to_s)
    post("/formation/assign", slot: "zz", player_id: player_id.to_s)

    expect(last_response.status).to eq(302)
    expect(lineup_slots.where(club_id: grimsby_id).count).to eq(0)
  end

  it "bench saca al jugador y vuelve a la ficha si viene return_to válido" do
    # setup: Grimsby + un jugador en "st".
    # exercise: post("/formation/bench", player_id: id.to_s, return_to: "/squad/#{id}")
    #           y otro post con return_to: "https://evil.example".
    # verify: lineup vacío; primer Location "/squad/#{id}", segundo "/formation".
  end

  it "auto rellena el once y clear lo vacía" do
    # setup: Grimsby + un portero (primary_position: 0) y un delantero (12).
    # exercise: post("/formation/auto"); guardar las filas; post("/formation/clear").
    # verify: tras auto, {"gk" => portero, "st" => delantero}; tras clear, 0 filas.
  end
end
```

Escribir los dos últimos `it` completos con el mismo setup inline de los anteriores.

- [ ] En `spec/requests/squad_show_spec.rb` añadir: un jugador en `st` → la ficha incluye "En el once · DC", "Quitar del campo" y `name="return_to" value="/squad/<id>"`; otro sin hueco → "Fuera del once" y sin "Quitar del campo".
- [ ] Rojo → implementar → verde. `bundle exec rake` completo.
- [ ] En el navegador: clic en un jugador de la lista → clic en un hueco; × en una ficha; Auto; Vaciar (con confirmación); "Quitar del campo" desde la ficha.

---

### Tarea 5.2: Insignia `XI` en la Plantilla

**Archivos:**
- Modificar: `app/actions/squad/index.rb`, `app/views/squad/index.rb`, `app/templates/squad/index.html.erb`
- Crear: `spec/requests/squad_index_lineup_spec.rb`

**Acción:**

```ruby
        include Deps["repos.player_repo", "repos.club_repo", "repos.lineup_repo"]

        def handle(request, response)
          players = player_repo.all

          response[:players] = players
          response[:lineup] = lineup_repo.for_club(club_repo.grimsby_town, players.map(&:id))
        end
```

Vista: `expose :players, :lineup`.

**Plantilla**, en la celda `col-name`, después del enlace con el nombre:

```erb
                <% if lineup.slot_of(player.id) %>
                  <span class="badge-xi">
                    XI
                  </span>
                <% end %>
```

**Pasos:**

- [ ] Spec: Grimsby con dos jugadores, uno en `st` (`lineup_slots.insert`). `get("/squad")` → el body tiene exactamente un `class="badge-xi"`.
- [ ] Rojo → implementar → verde.

---

## Etapa 6 — Arrastrar y soltar (depende de la Etapa 5)

> Hecha el 2026-11-03. Verificado con Playwright sobre una copia de la BD: lista → hueco vacío, lista → hueco ocupado, intercambio en el campo, soltar en el propio hueco (recarga sin cambios), campo → lista, lista → lista (no recarga), y Vaciar con Cancelar/confirmar. Soltar sin mover el ratón sobre una ficha es un clic y abre la ficha del jugador.

### Tarea 6.1: Drag & drop con forms ocultos + abrir diálogos

**Archivos:**
- Modificar: `app/assets/js/app.js`

**Cambios:**

1. El `dragstart` actual solo escucha `.bench-item[data-player-id]`. Ampliarlo a las fichas del campo y recordar de dónde viene el arrastre:

```js
// Jugador que se está arrastrando: true si sale del campo (Formación).
let dragFromPitch = false;

document.querySelectorAll(".bench-item[data-player-id], .token[data-player-id]").forEach((item) => {
  item.addEventListener("dragstart", (event) => {
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", item.dataset.playerId);
    dragFromPitch = item.closest("[data-slot]") !== null;
    item.classList.add("is-dragging");
  });

  item.addEventListener("dragend", () => item.classList.remove("is-dragging"));
});
```

2. Soltar en un hueco envía `#formation-drop-form`; soltar una ficha del campo en la lista envía `#formation-bench-form`. Soltar en la lista algo que viene de la lista no hace nada (evita recargar la página por nada):

```js
// Formación: soltar en un hueco coloca al jugador (intercambia si venía de otro hueco).
const dropForm = document.getElementById("formation-drop-form");

document.querySelectorAll("[data-slot]").forEach((zone) => {
  zone.addEventListener("dragover", (event) => {
    event.preventDefault();
    zone.classList.add("is-over");
  });

  zone.addEventListener("dragleave", () => zone.classList.remove("is-over"));

  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("is-over");

    const id = event.dataTransfer.getData("text/plain");
    if (!id || !dropForm) return;

    dropForm.elements.slot.value = zone.dataset.slot;
    dropForm.elements.player_id.value = id;
    dropForm.submit();
  });
});

// Formación: soltar una ficha del campo en la lista la saca del once.
const benchForm = document.getElementById("formation-bench-form");

document.querySelectorAll("[data-formation-bench]").forEach((zone) => {
  zone.addEventListener("dragover", (event) => {
    if (!dragFromPitch) return;

    event.preventDefault();
    zone.classList.add("is-over");
  });

  zone.addEventListener("dragleave", () => zone.classList.remove("is-over"));

  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("is-over");

    const id = event.dataTransfer.getData("text/plain");
    if (!id || !dragFromPitch || !benchForm) return;

    benchForm.elements.player_id.value = id;
    benchForm.submit();
  });
});

// Botones que abren un <dialog> por id (Vaciar en Formación).
document.querySelectorAll("[data-open-dialog]").forEach((button) => {
  button.addEventListener("click", () => {
    document.getElementById(button.dataset.openDialog)?.showModal();
  });
});
```

`.bench-list.is-over` ya tiene estilo rojo en `bench.css` (es la zona de "sacar del once" del prototipo).

**Pasos:**

- [ ] Implementar.
- [ ] Verificación manual (no hay specs de JS en el repo), en un servidor de puma en otro puerto:
  - lista → hueco vacío (entra);
  - lista → hueco ocupado (reemplaza; el anterior vuelve a la lista);
  - campo → hueco ocupado (intercambian);
  - campo → su propio hueco (no cambia nada);
  - campo → lista (sale del once);
  - lista → lista (no recarga).
- [ ] Que `/compare` y `/squad` sigan funcionando (drag de Comparar, modal "Liberar") sin errores en la consola.
- [ ] `bundle exec rake` completo y `bundle exec rubocop` sobre los archivos Ruby nuevos.
