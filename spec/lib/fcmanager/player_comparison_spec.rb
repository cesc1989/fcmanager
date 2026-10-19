# frozen_string_literal: true

RSpec.describe Fcmanager::PlayerComparison do
  it "compara promedio y edad como números aunque vengan como string" do
    player = Data.define(:name, :age, :overall, :primary_position, :player_traits)
    a = player.new(
      name: "Ana",
      age: "9",
      overall: "9",
      primary_position: "dc",
      player_traits: []
    )
    b = player.new(
      name: "Bea",
      age: "10",
      overall: "10",
      primary_position: "dc",
      player_traits: []
    )

    datos = described_class.new(a, b).sections.first

    promedio, edad = datos.rows
    expect(datos.title).to eq("Datos")
    expect([promedio.winner, promedio.diff_label]).to eq([:b, "+1 ▶"])
    expect([edad.winner, edad.diff_label]).to eq([nil, "◀ 1"])
    expect(edad.tooltip).to eq("Ana es 1 año más joven")
  end

  it "agrupa traits por kind, cuenta ganados y deja nil si falta un valor" do
    player = Data.define(:name, :age, :overall, :primary_position, :player_traits)
    trait = Data.define(:name, :kind)
    player_trait = Data.define(:value, :trait)
    sprint = trait.new(name: "Sprint", kind: "fisicos")
    fuerza = trait.new(name: "Fuerza", kind: "fisicos")
    vision = trait.new(name: "Visión", kind: "mentales")
    a = player.new(
      name: "Ana",
      age: "25",
      overall: "80",
      primary_position: "mc",
      player_traits: [
        player_trait.new(value: 90, trait: sprint),
        player_trait.new(value: 70, trait: fuerza),
        player_trait.new(value: 60, trait: vision)
      ]
    )
    b = player.new(
      name: "Bea",
      age: "25",
      overall: "80",
      primary_position: "mc",
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
    portero = player.new(
      name: "Por",
      age: "30",
      overall: "80",
      primary_position: "po",
      player_traits: traits
    )
    central = player.new(
      name: "Def",
      age: "30",
      overall: "80",
      primary_position: "dfc",
      player_traits: traits
    )
    punta = player.new(
      name: "Del",
      age: "30",
      overall: "80",
      primary_position: "dc",
      player_traits: traits
    )

    con_portero = described_class.new(portero, central)
    sin_portero = described_class.new(central, punta)

    expect(con_portero.sections.map(&:title)).to eq(%w[Datos ARQUERIA])
    expect(con_portero.different_lines?).to be(true)
    expect(sin_portero.sections.map(&:title)).to eq(%w[Datos])
  end
end
