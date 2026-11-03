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

    # "10" gana a "9" (comparación numérica, no de strings) y el extremo (90)
    # no entra en "st" porque la primera pasada ya lo llenó con un "dc".
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

  it "auto_fill ignora a jugadores fuera de la plantilla" do
    player = Data.define(:id, :primary_position, :overall)
    formation = Fcmanager::Formation.fetch("4-1-4-1")
    players = [
      player.new(id: 1, primary_position: "po", overall: "60"),
      player.new(id: 2, primary_position: "po", overall: "90")
    ]
    lineup = described_class.new(formation, {}, squad_ids: [1])

    result = lineup.auto_fill(players)

    expect(result.player_in("gk")).to eq(1)
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
