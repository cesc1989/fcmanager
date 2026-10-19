# Página Comparar Plan de Implementación

> **Para trabajadores agénticos:** SUB-HABILIDAD REQUERIDA: Usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para implementar este plan tarea por tarea. Los pasos usan casillas de verificación (`- [ ]`) para el seguimiento.

**Objetivo:** Traer la pestaña "Comparar" del prototipo a fcmanager: enfrentar a dos jugadores de la plantilla (cuadros A y B) con sus datos y traits lado a lado.

**Arquitectura:** Página renderizada en el servidor en `GET /compare?a=<id>&b=<id>`; la URL es el único estado (sin tabla ni `localStorage`). Dos objetos Ruby puros en `lib/fcmanager/` hacen el trabajo: `ComparePair` (qué jugador va en cada cuadro y los enlaces para cambiarlo) y `PlayerComparison` (filas enfrentadas, ganador, diferencias). Arrastrar y soltar es una mejora JS opcional que solo reescribe la URL.

**Stack Tecnológico:** Hanami 3.0.2, ROM/Sequel + SQLite, ERB, esbuild (`hanami-assets`), RSpec + Rack::Test, Ruby 3.4.

**Especificación:** Prototipo en `~/projects/devaspros-projects/prototipos/careermode-manager` — sección **Comparar** de su `README.md`, `js/compare.js`, `js/store.js` (`setCompare`, `compareWith`, `swapCompare`, `clearCompare`), `js/playerlist.js` y el bloque `/* ===== Comparar ===== */` de `css/styles.css`. Decisiones tomadas con el usuario (2026-10-18) que **reemplazan** al prototipo:

1. Estado en la URL `?a=&b=`, render en servidor.
2. Traits agrupados por `kind` (Físicos, Mentales, Técnicos, Arquería). Arquería solo aparece si uno de los dos es portero. No hay secciones "Solo X" (todos los jugadores tienen los 34 traits).
3. Arrastrar y soltar con JS ligero.
4. Botón "Comparar" en la ficha del jugador (`squad/show`).
5. Pestañas del header navegables.

## Restricciones Globales

- Namespace Ruby `Fcmanager` (c minúscula). Código nuevo de dominio en `lib/fcmanager/` (autoload Zeitwerk, igual que `players_catalog.rb`).
- Solo se comparan jugadores de la plantilla: `player_repo.all` (club "Grimsby Town"). Ids de otros clubes se ignoran.
- `players.age` y `players.overall` son `string` en la DB: convertir con `to_i` antes de comparar.
- `primary_position` llega como clave del enum (`"po"`, `"dfc"`, …, ver `app/relations/players.rb`). El grupo POR/DEF/MED/DEL sale de `PlayersCatalog::POSITIONS[:group]`.
- Orden de los kinds: `TraitsCatalog::KIND_ORDER` (`fisicos mentales tecnicos arqueria`); título de sección: `TraitsCatalog.kind_label(kind)`.
- Escala de color: helper `rating_class` (`is-elite` ≥80, `is-good` ≥74, `is-mid` ≥67, `is-low`).
- Textos en español tal cual el prototipo: "Jugador A", "Jugador B", "Arrastra aquí un jugador", "— elegir jugador —", "Carga dos jugadores para ver la comparación.", "Falta un jugador en el cuadro A|B.", "Sin comentarios todavía.", "Vaciar", "⇄", "×".
- Etiqueta de diferencia: modo `higher` → `◀ +N` (gana A) / `+N ▶` (gana B); modo `neutral` (Edad) → `N ▶` / `◀ N` (la flecha apunta al menor); empate `=`.
- Puerto 2300. Tests: `bundle exec rspec`. Lint: `bundle exec rubocop` sobre archivos nuevos.
- Specs: todo dentro del `it`, four-phase (setup / exercise / verify), sin `let`/`before`, como `spec/requests/squad_release_spec.rb`.

## Enfoque de Revisión

1. **Params basura o ajenos** (`?a=abc`, `?a=`, `?a=012`, id inexistente, id de un jugador liberado a "Agente Libre") → la página responde 200 y ese cuadro queda vacío. Prueba: Tarea 1.1 (`from_params`) y Tarea 2.1 (request).
2. **Mismo jugador en A y B** (`?a=5&b=5`) → B queda vacío, no se compara un jugador consigo mismo. Prueba: Tarea 1.1 y Tarea 2.1.
3. **`overall`/`age` como string** (`"9"` vs `"10"`) → gana 10; una comparación de strings daría 9. Prueba: Tarea 1.2.
4. **Jugador con traits incompletos** (creado antes de añadir un trait) → la fila muestra `—` en ese lado, sin ganador, y no cuenta en el resumen. Prueba: Tarea 1.2.
5. **Portero vs jugador de campo / dos de campo** → la sección ARQUERIA aparece solo si hay un portero. Prueba: Tarea 1.2 y Tarea 2.1.

---

## Etapa 1 — Dominio (tareas independientes)

### Tarea 1.1: `ComparePair`

Representa qué jugador está en cada cuadro y produce las parejas de los enlaces (clic en la lista, ⇄, ×).

**Archivos:**
- Crear: `lib/fcmanager/compare_pair.rb`
- Crear: `spec/lib/fcmanager/compare_pair_spec.rb`

**Interfaz:**

```ruby
# frozen_string_literal: true

module Fcmanager
  # Pareja de jugadores de la página Comparar (cuadros A y B), tomada de `?a=&b=`.
  #
  # Es inmutable: cada operación devuelve una pareja nueva y `to_params` da los
  # query params del enlace correspondiente.
  class ComparePair
    attr_reader :a, :b

    # Descarta ids que no son enteros en base 10 o que no están en `allowed_ids`
    # (los ids de la plantilla).
    def self.from_params(params, allowed_ids)
      ids = %i[a b].map do |box|
        id = Integer(params[box].to_s, 10, exception: false)
        allowed_ids.include?(id) ? id : nil
      end

      new(*ids)
    end

    def initialize(a = nil, b = nil)
      @a = a
      @b = b == a ? nil : b
    end

    def complete?
      !a.nil? && !b.nil?
    end

    # :a, :b o nil.
    def box_of(id)
      return :a if !id.nil? && id == a
      return :b if !id.nil? && id == b

      nil
    end

    # Clic en la lista: primer cuadro libre; si los dos están ocupados reemplaza el B.
    # Si el jugador ya está en un cuadro, no cambia nada.
    def with(id)
      return self if box_of(id)

      a.nil? ? self.class.new(id, b) : self.class.new(a, id)
    end

    def swap
      self.class.new(b, a)
    end

    def without(box)
      box == :a ? self.class.new(nil, b) : self.class.new(a, nil)
    end

    def to_params
      {a: a, b: b}.compact
    end
  end
end
```

**Pasos:**

- [ ] Escribir el spec (sin DB, no lleva `:db`):

```ruby
# frozen_string_literal: true

RSpec.describe Fcmanager::ComparePair do
  it "toma los ids de los params si están en la plantilla" do
    params = {a: "3", b: "7"}

    pair = described_class.from_params(params, [3, 7, 9])

    expect(pair.to_params).to eq(a: 3, b: 7)
  end

  it "descarta ids no numéricos, vacíos, con ceros a la izquierda raros o fuera de la plantilla" do
    allowed = [3, 10]

    pairs = [
      described_class.from_params({a: "abc", b: ""}, allowed),
      described_class.from_params({a: "99"}, allowed),
      described_class.from_params({a: "3x"}, allowed)
    ]

    expect(pairs.map(&:to_params)).to eq([{}, {}, {}])
    expect(described_class.from_params({a: "010"}, allowed).a).to eq(10)
  end

  it "vacía B si es el mismo jugador que A" do
    params = {a: "3", b: "3"}

    pair = described_class.from_params(params, [3])

    expect(pair.to_params).to eq(a: 3)
  end

  it "with carga en el primer cuadro libre y reemplaza B si están llenos" do
    empty = described_class.new
    only_b = described_class.new(nil, 7)
    full = described_class.new(3, 7)

    results = [empty.with(5), only_b.with(5), full.with(5), full.with(3)]

    expect(results.map(&:to_params)).to eq([
      {a: 5},
      {a: 5, b: 7},
      {a: 3, b: 5},
      {a: 3, b: 7}
    ])
  end

  it "swap, without y box_of" do
    pair = described_class.new(3, 7)

    swapped = pair.swap
    without_a = pair.without(:a)

    expect(swapped.to_params).to eq(a: 7, b: 3)
    expect(without_a.to_params).to eq(b: 7)
    expect([pair.box_of(3), pair.box_of(7), pair.box_of(9)]).to eq([:a, :b, nil])
    expect([pair.complete?, without_a.complete?]).to eq([true, false])
  end
end
```

  Nota: `Integer("010", 10)` es `10` (sin el 10 en base, `Integer("010")` sería `8`). El caso del spec lo fija.

- [ ] `bundle exec rspec spec/lib/fcmanager/compare_pair_spec.rb` → falla; implementar; pasa.
- [ ] `bundle exec rubocop lib/fcmanager/compare_pair.rb spec/lib/fcmanager/compare_pair_spec.rb`.

---

### Tarea 1.2: `PlayerComparison` + grupos en `PlayersCatalog`

**Archivos:**
- Modificar: `lib/fcmanager/players_catalog.rb`
- Crear: `lib/fcmanager/player_comparison.rb`
- Crear: `spec/lib/fcmanager/player_comparison_spec.rb`

**Cambio en `PlayersCatalog`** (añadir debajo de `POSITION_ORDER` y dentro de `module_function`):

```ruby
    # Líneas del equipo, del portero al delantero (lista de la página Comparar).
    GROUPS = [
      {key: "POR", label: "Porteros"},
      {key: "DEF", label: "Defensas"},
      {key: "MED", label: "Mediocampistas"},
      {key: "DEL", label: "Delanteros"}
    ].freeze

    POSITION_GROUP = POSITIONS.to_h { |position| [position[:key], position[:group]] }.freeze
```

```ruby
    # Posición (clave de la relación) → línea: "POR", "DEF", "MED" o "DEL".
    def group_of(key)
      POSITION_GROUP.fetch(key.to_s, "MED")
    end
```

**Interfaz de `PlayerComparison`:**

```ruby
# frozen_string_literal: true

module Fcmanager
  # Enfrenta a dos jugadores para la página Comparar.
  #
  # Los jugadores deben venir con `player_traits: :trait` combinados (ver
  # `PlayerRepo#all`). `age` y `overall` se guardan como string en la DB, así
  # que aquí se pasan a entero antes de comparar.
  class PlayerComparison
    # Una fila enfrentada. `a`/`b` son nil si ese jugador no tiene el trait.
    # mode: :higher (gana el más alto) o :neutral (sin ganador, p. ej. la edad).
    Row = Data.define(:label, :a, :b, :mode, :tooltip) do
      def initialize(label:, a:, b:, mode: :higher, tooltip: nil)
        super
      end

      def both?
        !a.nil? && !b.nil?
      end

      def diff
        both? ? a - b : nil
      end

      # :a, :b o nil (empate, modo neutral o falta un valor).
      def winner
        return nil unless mode == :higher && both? && !diff.zero?

        diff.positive? ? :a : :b
      end

      def diff_label
        return nil unless both?
        return "=" if diff.zero?

        size = diff.abs
        if mode == :higher
          diff.positive? ? "◀ +#{size}" : "+#{size} ▶"
        else
          diff.positive? ? "#{size} ▶" : "◀ #{size}"
        end
      end
    end

    Section = Data.define(:title, :rows)

    attr_reader :a, :b

    def initialize(a, b)
      @a = a
      @b = b
    end

    # "Datos" (Promedio, Edad) seguido de una sección por kind de trait.
    def sections
      [data_section, *trait_sections]
    end

    # Cuántos traits gana cada uno; solo filas de traits con valor en ambos lados.
    def wins
      rows = trait_sections.flat_map(&:rows).select(&:both?)

      {
        a: rows.count { |row| row.winner == :a },
        b: rows.count { |row| row.winner == :b },
        tie: rows.count { |row| row.diff.zero? }
      }
    end

    def different_lines?
      group(a) != group(b)
    end

    private

    def data_section
      Section.new(
        title: "Datos",
        rows: [
          Row.new(label: "Promedio", a: a.overall.to_i, b: b.overall.to_i),
          Row.new(label: "Edad", a: a.age.to_i, b: b.age.to_i, mode: :neutral, tooltip: age_tooltip)
        ]
      )
    end

    def trait_sections
      @trait_sections ||= kinds.filter_map do |kind|
        names = trait_names(kind)
        next if names.empty?

        rows = names.map do |name|
          Row.new(label: name, a: trait_value(a, name), b: trait_value(b, name))
        end

        Section.new(title: TraitsCatalog.kind_label(kind), rows: rows)
      end
    end

    # Arquería solo cuenta si alguno de los dos es portero.
    def kinds
      return TraitsCatalog::KIND_ORDER if [a, b].any? { |player| group(player) == "POR" }

      TraitsCatalog::KIND_ORDER - ["arqueria"]
    end

    # Unión de los traits de ambos de ese kind, para no perder los que tiene solo uno.
    def trait_names(kind)
      [a, b].flat_map(&:player_traits)
        .select { |pt| pt.trait.kind.to_s == kind }
        .map { |pt| pt.trait.name }
        .uniq
        .sort
    end

    def trait_value(player, name)
      player.player_traits.find { |pt| pt.trait.name == name }&.value
    end

    def age_tooltip
      diff = a.age.to_i - b.age.to_i
      return nil if diff.zero?

      younger = diff.positive? ? b : a
      years = diff.abs
      "#{younger.name} es #{years} #{years == 1 ? "año" : "años"} más joven"
    end

    def group(player)
      PlayersCatalog.group_of(player.primary_position)
    end
  end
end
```

**Pasos:**

- [ ] Escribir el spec. Usa `Data` locales en vez de la DB (el objeto solo necesita duck typing). Cada `it` define lo que usa:

```ruby
# frozen_string_literal: true

RSpec.describe Fcmanager::PlayerComparison do
  it "compara promedio y edad como números aunque vengan como string" do
    player = Data.define(:name, :age, :overall, :primary_position, :player_traits)
    a = player.new(name: "Ana", age: "9", overall: "9", primary_position: "dc", player_traits: [])
    b = player.new(name: "Bea", age: "10", overall: "10", primary_position: "dc", player_traits: [])

    datos = described_class.new(a, b).sections.first

    promedio, edad = datos.rows
    expect(datos.title).to eq("Datos")
    expect([promedio.winner, promedio.diff_label]).to eq([:b, "+1 ▶"])
    expect([edad.winner, edad.diff_label]).to eq([nil, "◀ 1"])
    expect(edad.tooltip).to eq("Ana es 1 año más joven")
  end

  it "agrupa traits por kind, cuenta ganados y deja — si falta un valor" do
    player = Data.define(:name, :age, :overall, :primary_position, :player_traits)
    trait = Data.define(:name, :kind)
    player_trait = Data.define(:value, :trait)
    sprint = trait.new(name: "Sprint", kind: "fisicos")
    fuerza = trait.new(name: "Fuerza", kind: "fisicos")
    vision = trait.new(name: "Visión", kind: "mentales")
    a = player.new(
      name: "Ana", age: "25", overall: "80", primary_position: "mc",
      player_traits: [
        player_trait.new(value: 90, trait: sprint),
        player_trait.new(value: 70, trait: fuerza),
        player_trait.new(value: 60, trait: vision)
      ]
    )
    b = player.new(
      name: "Bea", age: "25", overall: "80", primary_position: "mc",
      player_traits: [
        player_trait.new(value: 80, trait: sprint),
        player_trait.new(value: 70, trait: fuerza)
      ]
    )

    comparison = described_class.new(a, b)

    sections = comparison.sections
    vision_row = sections.last.rows.first
    expect(sections.map(&:title)).to eq(%w[Datos FISICOS MENTALES])
    expect(sections[1].rows.map(&:label)).to eq(%w[Fuerza Sprint])
    expect([vision_row.a, vision_row.b, vision_row.winner, vision_row.diff_label]).to eq([60, nil, nil, nil])
    expect(comparison.wins).to eq(a: 1, b: 0, tie: 1)
  end

  it "muestra arquería solo si uno de los dos es portero" do
    player = Data.define(:name, :age, :overall, :primary_position, :player_traits)
    trait = Data.define(:name, :kind)
    player_trait = Data.define(:value, :trait)
    reflejos = trait.new(name: "Reflejos", kind: "arqueria")
    traits = [player_trait.new(value: 50, trait: reflejos)]
    portero = player.new(name: "Por", age: "30", overall: "80", primary_position: "po", player_traits: traits)
    central = player.new(name: "Def", age: "30", overall: "80", primary_position: "dfc", player_traits: traits)
    punta = player.new(name: "Del", age: "30", overall: "80", primary_position: "dc", player_traits: traits)

    con_portero = described_class.new(portero, central)
    sin_portero = described_class.new(central, punta)

    expect(con_portero.sections.map(&:title)).to eq(%w[Datos ARQUERIA])
    expect(con_portero.different_lines?).to be(true)
    expect(sin_portero.sections.map(&:title)).to eq(%w[Datos])
  end
end
```

- [ ] `bundle exec rspec spec/lib/fcmanager/player_comparison_spec.rb` → falla; implementar; pasa.
- [ ] `bundle exec rubocop` sobre los tres archivos.

---

## Etapa 2 — Página `/compare` (depende de la Etapa 1)

### Tarea 2.1: Ruta, acción, vista, plantilla y CSS

**Archivos:**
- Modificar: `config/routes.rb`
- Crear: `app/actions/compare/show.rb`
- Crear: `app/views/compare/show.rb`
- Crear: `app/templates/compare/show.html.erb`
- Modificar: `app/views/helpers.rb`
- Crear: `app/assets/css/compare.css`
- Modificar: `app/assets/js/app.js` (solo el `import` del CSS)
- Crear: `spec/requests/compare_spec.rb`

**Ruta** (añadir al final del bloque en `config/routes.rb`):

```ruby
    get "/compare", to: "compare.show", as: :compare
```

`routes.path(:compare, a: 3, b: 7)` → `/compare?a=3&b=7`: hanami-router agrega como query string las variables que no están en la ruta (`expand(:append, …)`).

**Acción:**

```ruby
# frozen_string_literal: true

module Fcmanager
  module Actions
    module Compare
      class Show < Fcmanager::Action
        include Deps["repos.player_repo"]

        def handle(request, response)
          players = player_repo.all
          pair = ComparePair.from_params(request.params, players.map(&:id))
          player_a = players.find { |player| player.id == pair.a }
          player_b = players.find { |player| player.id == pair.b }

          response[:players] = players
          response[:pair] = pair
          response[:player_a] = player_a
          response[:player_b] = player_b
          response[:comparison] = pair.complete? ? PlayerComparison.new(player_a, player_b) : nil
        end
      end
    end
  end
end
```

**Vista:**

```ruby
# frozen_string_literal: true

module Fcmanager
  module Views
    module Compare
      class Show < Fcmanager::View
        expose :players, :pair, :player_a, :player_b, :comparison
      end
    end
  end
end
```

**Helpers nuevos** (en `app/views/helpers.rb`, junto a los demás públicos):

```ruby
      # Plantilla agrupada por línea para la lista de la página Comparar.
      def grouped_squad(players)
        PlayersCatalog::GROUPS.filter_map do |group|
          members = players.select { |player| PlayersCatalog.group_of(player.primary_position) == group[:key] }
          next if members.empty?

          {key: group[:key], label: group[:label], players: members}
        end
      end

      def compare_path(pair)
        routes.path(:compare, **pair.to_params)
      end
```

**Plantilla** `app/templates/compare/show.html.erb`. Estructura del prototipo (`index.html` sección COMPARAR + `compare.js`), adaptada a enlaces:

- Lista: cada jugador es un `<a class="bench-item">` hacia `compare_path(pair.with(player.id))`; si `pair.box_of(player.id)` añade `is-on-pitch` y el badge `A`/`B`. Lleva `draggable="true"` y `data-player-id` (los usa la Tarea 3.1).
- Cuadros: `data-compare-box="a|b"` (zona de soltar de la Tarea 3.1). × → `compare_path(pair.without(:a))`. ⇄ → `compare_path(pair.swap)`. "Vaciar" → `routes.path(:compare)`.
- Desplegable: `<form method="get">` con un `select` para el cuadro y un `hidden` con el id del otro cuadro. Lleva la clase `js-autosubmit`; dentro de un `<noscript>`, un botón "Cargar" por si no hay JS.

```erb
<main>
  <section class="compare-layout">
    <aside class="bench">
      <div class="bench-head">
        <h2>
          Jugadores
        </h2>

        <div class="row-actions">
          <a href="<%= routes.path(:compare) %>"
             class="btn ghost sm"
          >
            Vaciar
          </a>
        </div>
      </div>

      <p class="hint">
        Arrastra un jugador a un cuadro, o haz clic para cargarlo en el primero libre.
      </p>

      <div class="bench-list">
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
            <% box = pair.box_of(player.id) %>

            <a href="<%= compare_path(pair.with(player.id)) %>"
               class="bench-item <%= "is-on-pitch" if box %>"
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

              <% if box %>
                <span class="badge-xi">
                  <%= box.to_s.upcase %>
                </span>
              <% end %>

              <span class="ovr <%= rating_class(player.overall) %>">
                <%= player.overall %>
              </span>
            </a>
          <% end %>
        <% end %>
      </div>
    </aside>

    <div class="compare-panel">
      <div class="compare-boxes">
        <%= render "compare/box", box: :a, player: player_a, pair: pair, players: players %>

        <a href="<%= compare_path(pair.swap) %>"
           class="btn ghost swap-btn"
           title="Intercambiar jugadores"
        >
          ⇄
        </a>

        <%= render "compare/box", box: :b, player: player_b, pair: pair, players: players %>
      </div>

      <div class="compare-result">
        <% if comparison %>
          <%= render "compare/result", comparison: comparison %>
        <% else %>
          <div class="cmp-placeholder">
            <p>
              <%= pair.a || pair.b ? "Falta un jugador en el cuadro #{pair.a ? "B" : "A"}." : "Carga dos jugadores para ver la comparación." %>
            </p>

            <p class="hint">
              Arrástralos desde la lista, elígelos en el desplegable de cada cuadro, o pulsa “Comparar” en la ficha de un jugador.
            </p>
          </div>
        <% end %>
      </div>
    </div>
  </section>
</main>
```

Parcial `app/templates/compare/_box.html.erb` (el `other` es el id del otro cuadro, que viaja oculto en el form):

```erb
<% other = box == :a ? :b : :a %>

<div class="compare-box <%= player ? "is-filled" : "is-empty" %>"
     data-compare-box="<%= box %>"
>
  <div class="compare-box-head">
    <span class="compare-box-title">
      Jugador <%= box.to_s.upcase %>
    </span>

    <% if player %>
      <a href="<%= compare_path(pair.without(box)) %>"
         class="icon-btn"
         title="Quitar del cuadro"
      >
        ×
      </a>
    <% end %>
  </div>

  <% if player %>
    <% position = position_info(player.primary_position) %>

    <div class="compare-box-player">
      <div class="compare-box-meta">
        <a href="<%= routes.path(:squad_player, id: player.id) %>"
           class="link-name compare-name"
           title="Ver ficha completa"
        >
          <%= player.name %>
        </a>

        <div class="card-line">
          <span class="pos-tag pos-<%= position[:group] %>"
                title="<%= position[:label] %>"
          >
            <%= position[:short] %>
          </span>

          <span class="muted">
            <%= player.age %> años · <%= role_label(player.role) %>
          </span>
        </div>
      </div>

      <div class="ovr-big <%= rating_class(player.overall) %>">
        <span class="ovr-value">
          <%= player.overall %>
        </span>

        <span class="ovr-label">
          PROM
        </span>
      </div>
    </div>
  <% else %>
    <div class="compare-drop">
      Arrastra aquí un jugador
    </div>
  <% end %>

  <form method="get"
        action="<%= routes.path(:compare) %>"
        class="js-autosubmit"
  >
    <% if pair.public_send(other) %>
      <input type="hidden"
             name="<%= other %>"
             value="<%= pair.public_send(other) %>"
      >
    <% end %>

    <select name="<%= box %>"
            class="input compare-picker"
    >
      <option value="">
        — elegir jugador —
      </option>

      <% players.each do |option| %>
        <option value="<%= option.id %>" <%= "selected" if option.id == player&.id %>>
          <%= position_info(option.primary_position)[:short] %> · <%= option.name %> (<%= option.overall %>)
        </option>
      <% end %>
    </select>

    <noscript>
      <button type="submit"
              class="btn ghost sm"
      >
        Cargar
      </button>
    </noscript>
  </form>
</div>
```

Parcial `app/templates/compare/_result.html.erb`. Por cada fila: lado A (valor + barra alineada a la derecha), centro (label + chip de diferencia), lado B (barra + valor). Clases del prototipo: `is-better` en el valor y la barra del ganador, `is-none` y `—` si el valor es nil; ancho de barra `[value, 4].max %`.

```erb
<% wins = comparison.wins %>

<div class="cmp-summary">
  <span class="chip">
    <%= comparison.a.name %> gana <%= wins[:a] %>
  </span>

  <span class="chip">
    Empates <%= wins[:tie] %>
  </span>

  <span class="chip">
    <%= comparison.b.name %> gana <%= wins[:b] %>
  </span>

  <% if comparison.different_lines? %>
    <span class="chip warn">
      Líneas distintas
    </span>
  <% end %>
</div>

<% comparison.sections.each do |section| %>
  <div class="cmp-section">
    <h4 class="card-subtitle">
      <%= section.title %>
    </h4>

    <% section.rows.each do |row| %>
      <div class="cmp-row">
        <% [:a, :b].each do |side| %>
          <% value = row.public_send(side) %>

          <% if side == :b %>
            <div class="cmp-middle">
              <span class="cmp-label">
                <%= row.label %>
              </span>

              <% if row.diff_label %>
                <span class="cmp-diff <%= "is-tie" if row.diff.zero? %> <%= "is-neutral" if row.mode == :neutral %>"
                      title="<%= row.tooltip %>"
                >
                  <%= row.diff_label %>
                </span>
              <% end %>
            </div>
          <% end %>

          <div class="cmp-side cmp-<%= side %>">
            <% value_html = capture do %>
              <span class="cmp-value <%= "is-better" if row.winner == side %> <%= "is-none" if value.nil? %>">
                <%= value.nil? ? "—" : value %>
              </span>
            <% end %>

            <% track_html = capture do %>
              <span class="cmp-track">
                <% unless value.nil? %>
                  <span class="cmp-fill <%= rating_class(value) %> <%= "is-better" if row.winner == side %>"
                        style="width: <%= [value, 4].max %>%"
                  >
                  </span>
                <% end %>
              </span>
            <% end %>

            <%= side == :a ? value_html + track_html : track_html + value_html %>
          </div>
        <% end %>
      </div>
    <% end %>
  </div>
<% end %>

<div class="cmp-section">
  <h4 class="card-subtitle">
    Comentarios
  </h4>

  <div class="cmp-notes">
    <% [comparison.a, comparison.b].each do |player| %>
      <div class="cmp-note">
        <h5>
          <%= player.name %>
        </h5>

        <p class="card-comment">
          <%= player.comment.to_s.empty? ? "Sin comentarios todavía." : player.comment %>
        </p>
      </div>
    <% end %>
  </div>
</div>
```

  Opción abierta: si `capture` no está disponible en el scope de Hanami View o queda confuso, escribir los dos lados por separado sin el `each` (es más largo, pero más claro). Lo que importa es el orden: A = valor + barra, B = barra + valor.

**CSS** `app/assets/css/compare.css`: copiar del `css/styles.css` del prototipo los bloques `.bench` … `.bench-sub` (líneas ~201–242) y todo `/* ===== Comparar ===== */` hasta antes de `/* ===== Modal ===== */`, incluido el `@media (max-width: 720px)`. Cambios:

```css
/* En el prototipo era .formation-layout, compartido con Formación. */
.compare-layout {
  display: grid;
  grid-template-columns: 340px minmax(0, 1fr);
  gap: 18px;
  align-items: start;
}

/* Los ítems de la lista y el botón ⇄ ahora son enlaces. */
.bench-item { color: inherit; text-decoration: none; }
.swap-btn { text-align: center; text-decoration: none; }

@media (max-width: 900px) {
  .compare-layout { grid-template-columns: 1fr; }
  .bench { position: static; }
}
```

No copiar lo que ya existe en `card.css`/`plantilla.css`/`controls.css`: `.row-actions`, `.chip`, `.ovr*`, `.pos-tag`, `.badge-xi`, `.icon-btn`, `.link-name`, `.card-*`. Revisar visualmente.

En `app/assets/js/app.js`, debajo de `import "../css/card.css";`:

```js
import "../css/compare.css";
```

**Pasos:**

- [ ] Escribir `spec/requests/compare_spec.rb`:

```ruby
# frozen_string_literal: true

RSpec.describe "Compare", :db, type: :request do
  it "sin params lista la plantilla y pide dos jugadores" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    other_id = clubs.insert(name: "Agente Libre")
    players.insert(name: "Theo Marchal", age: "27", overall: "83", role: 4, height: "180",
      dominant_foot: 0, primary_position: 12, club_id: grimsby_id)
    players.insert(name: "Fuera De Plantilla", age: "27", overall: "70", role: 0, height: "180",
      dominant_foot: 0, primary_position: 12, club_id: other_id)

    get("/compare")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include("Theo Marchal")
    expect(last_response.body).not_to include("Fuera De Plantilla")
    expect(last_response.body).to include("Carga dos jugadores para ver la comparación.")
  end

  it "compara dos jugadores con traits por kind y arquería solo con portero" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    traits = Hanami.app["relations.traits"]
    player_traits = Hanami.app["relations.player_traits"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    sprint_id = traits.insert(name: "Sprint", kind: 0)
    reflejos_id = traits.insert(name: "Reflejos", kind: 3)
    a_id = players.insert(name: "Ana Delantera", age: "24", overall: "80", role: 4, height: "175",
      dominant_foot: 0, primary_position: 12, club_id: grimsby_id, comment: "Muy rápida")
    b_id = players.insert(name: "Bea Central", age: "29", overall: "76", role: 3, height: "182",
      dominant_foot: 0, primary_position: 2, club_id: grimsby_id)
    player_traits.insert(player_id: a_id, trait_id: sprint_id, value: 90)
    player_traits.insert(player_id: b_id, trait_id: sprint_id, value: 70)
    player_traits.insert(player_id: a_id, trait_id: reflejos_id, value: 20)
    player_traits.insert(player_id: b_id, trait_id: reflejos_id, value: 20)

    get("/compare", a: a_id, b: b_id)

    body = last_response.body
    expect(last_response.status).to eq(200)
    expect(body).to include("Ana Delantera gana 1")
    expect(body).to include("FISICOS")
    expect(body).not_to include("ARQUERIA")
    expect(body).to include("◀ +20")
    expect(body).to include("Muy rápida")
    expect(body).to include("Sin comentarios todavía.")
  end

  it "ignora ids basura, ajenos a la plantilla o repetidos" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    free_agent_id = clubs.insert(name: "Agente Libre")
    a_id = players.insert(name: "Ana", age: "24", overall: "80", role: 4, height: "175",
      dominant_foot: 0, primary_position: 12, club_id: grimsby_id)
    released_id = players.insert(name: "Liberado", age: "24", overall: "80", role: 4, height: "175",
      dominant_foot: 0, primary_position: 12, club_id: free_agent_id)

    responses = [
      get("/compare", a: "abc", b: "999999"),
      get("/compare", a: a_id, b: a_id),
      get("/compare", a: a_id, b: released_id)
    ]

    expect(responses.map(&:status)).to eq([200, 200, 200])
    expect(responses[0].body).to include("Carga dos jugadores para ver la comparación.")
    expect(responses[1].body).to include("Falta un jugador en el cuadro B.")
    expect(responses[2].body).to include("Falta un jugador en el cuadro B.")
  end

  it "los enlaces de la lista y de los cuadros llevan la pareja correcta" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    a_id = players.insert(name: "Ana", age: "24", overall: "80", role: 4, height: "175",
      dominant_foot: 0, primary_position: 12, club_id: grimsby_id)
    b_id = players.insert(name: "Bea", age: "24", overall: "80", role: 4, height: "175",
      dominant_foot: 0, primary_position: 12, club_id: grimsby_id)

    get("/compare", a: a_id)

    body = last_response.body
    expect(body).to include(%(href="/compare?a=#{a_id}&amp;b=#{b_id}"))
    expect(body).to include(%(href="/compare?b=#{a_id}"))
    expect(body).to include(%(href="/compare"))
    expect(body).to include(%(data-compare-box="a"))
  end
end
```

  El escape de `&` en atributos puede ser `&amp;` o `&`, según cómo escape ERB las URLs en Hanami. Ajustar la expectativa a lo que salga, pero comprobar que los dos ids están en la URL.

- [ ] Correr el spec → falla; implementar ruta, acción, vista, helpers, plantillas y CSS; pasa.
- [ ] `bundle exec rake` completo (no romper `squad_*`).
- [ ] `bin/dev` y revisar `http://localhost:2300/compare` contra el prototipo (`python3 -m http.server 8080` en la carpeta del prototipo, pestaña Comparar), también con ancho de móvil.

---

## Etapa 3 — Integraciones (tareas independientes entre sí; dependen de la Etapa 2)

### Tarea 3.1: Arrastrar y soltar + autoenvío del desplegable

**Archivos:**
- Modificar: `app/assets/js/app.js`

Añadir al final del archivo:

```js
// Comparar: al cambiar el desplegable de un cuadro se envía su formulario.
document.querySelectorAll(".js-autosubmit select").forEach((select) => {
  select.addEventListener("change", () => select.form.requestSubmit());
});

// Comparar: arrastrar un jugador de la lista a un cuadro reescribe ?a=&b=.
// Si el jugador ya estaba en el otro cuadro, los dos se intercambian (como el
// setCompare del prototipo). El servidor vuelve a validar los ids.
document.querySelectorAll(".bench-item[data-player-id]").forEach((item) => {
  item.addEventListener("dragstart", (event) => {
    event.dataTransfer.effectAllowed = "move";
    event.dataTransfer.setData("text/plain", item.dataset.playerId);
    item.classList.add("is-dragging");
  });
  item.addEventListener("dragend", () => item.classList.remove("is-dragging"));
});

document.querySelectorAll("[data-compare-box]").forEach((zone) => {
  zone.addEventListener("dragover", (event) => {
    event.preventDefault();
    zone.classList.add("is-over");
  });
  zone.addEventListener("dragleave", () => zone.classList.remove("is-over"));
  zone.addEventListener("drop", (event) => {
    event.preventDefault();
    zone.classList.remove("is-over");

    const id = event.dataTransfer.getData("text/plain");
    if (!id) return;

    const box = zone.dataset.compareBox;
    const other = box === "a" ? "b" : "a";
    const params = new URLSearchParams(window.location.search);

    if (params.get(other) === id) {
      const current = params.get(box);
      current ? params.set(other, current) : params.delete(other);
    }
    params.set(box, id);
    window.location.search = params.toString();
  });
});
```

**Pasos:**

- [ ] Implementar.
- [ ] Verificación manual con `bin/dev` (no hay specs de JS en el repo): soltar en A vacío, soltar en B ocupado (reemplaza), soltar en A un jugador que está en B (intercambian), elegir en el desplegable (se recarga sin pulsar botón). Que `/squad` siga funcionando (modal "Liberar"): los selectores nuevos no encuentran nada en esa página y no deben dar errores en la consola.

---

### Tarea 3.2: Botón "Comparar" en la ficha del jugador

**Archivos:**
- Modificar: `app/templates/squad/show.html.erb`
- Crear: `spec/requests/squad_show_spec.rb`

En `.row-actions`, entre "← Volver" y "Editar":

```erb
      <div class="row-actions">
        <a href="<%= routes.path(:squad) %>" class="btn ghost sm">← Volver</a>

        <a href="<%= routes.path(:compare, a: player.id) %>"
           class="btn ghost sm"
        >
          Comparar
        </a>

        <a href="<%= routes.path(:edit_squad, id: player.id) %>" class="btn primary sm">Editar</a>
      </div>
```

**Pasos:**

- [ ] Spec:

```ruby
# frozen_string_literal: true

RSpec.describe "Squad show", :db, type: :request do
  it "enlaza a Comparar con el jugador en el cuadro A" do
    clubs = Hanami.app["relations.clubs"]
    players = Hanami.app["relations.players"]
    grimsby_id = clubs.insert(name: "Grimsby Town")
    player_id = players.insert(name: "Ana", age: "24", overall: "80", role: 4, height: "175",
      dominant_foot: 0, primary_position: 12, club_id: grimsby_id)

    get("/squad/#{player_id}")

    expect(last_response.status).to eq(200)
    expect(last_response.body).to include(%(href="/compare?a=#{player_id}"))
  end
end
```

- [ ] Rojo → implementar → verde.

---

### Tarea 3.3: Pestañas navegables

**Archivos:**
- Modificar: `app/templates/layouts/app.html.erb`
- Modificar: `app/views/helpers.rb`
- Modificar: `app/assets/css/header.css`
- Crear: `spec/requests/tabs_spec.rb`

**Helper** (el `request` existe en el contexto de la vista cuando la renderiza una acción; `request?` lo protege si no hay request):

```ruby
      # Clase de una pestaña del header según la ruta actual.
      def tab_class(section)
        path = request? ? request.path : ""
        active = case section
                 when :squad then path == "/" || path.start_with?("/squad")
                 when :compare then path.start_with?("/compare")
                 else false
                 end

        active ? "tab is-active" : "tab"
      end
```

**Layout**, reemplazar el `<nav class="tabs">` actual:

```erb
      <nav class="tabs">
        <a href="<%= routes.path(:squad) %>"
           class="<%= tab_class(:squad) %>"
        >
          Plantilla
        </a>

        <span class="tab is-disabled"
              title="Próximamente"
        >
          Formación
        </span>

        <a href="<%= routes.path(:compare) %>"
           class="<%= tab_class(:compare) %>"
        >
          Comparar
        </a>
      </nav>
```

**CSS** (`header.css`, debajo de `.tab.is-active`):

```css
a.tab { text-decoration: none; display: inline-block; }
.tab.is-disabled { opacity: .4; cursor: not-allowed; }
.tab.is-disabled:hover { color: var(--muted); }
```

**Pasos:**

- [ ] Spec:

```ruby
# frozen_string_literal: true

RSpec.describe "Header tabs", :db, type: :request do
  it "marca la pestaña activa según la ruta" do
    clubs = Hanami.app["relations.clubs"]
    clubs.insert(name: "Grimsby Town")

    squad_body = get("/squad").body
    compare_body = get("/compare").body

    expect(squad_body).to match(%r{href="/squad"\s+class="tab is-active"})
    expect(squad_body).to match(%r{href="/compare"\s+class="tab"})
    expect(compare_body).to match(%r{href="/compare"\s+class="tab is-active"})
    expect(compare_body).to match(%r{href="/squad"\s+class="tab"})
  end
end
```

- [ ] Rojo → implementar → verde. `bundle exec rake` completo.
- [ ] Revisar en el navegador que las pestañas mantienen el estilo de botón.
