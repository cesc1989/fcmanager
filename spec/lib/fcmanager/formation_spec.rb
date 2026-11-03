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

  it "los enteros de los huecos coinciden con el enum de lineup_slots" do
    formation = described_class.fetch("4-1-4-1")
    slot_type = Hanami.app["relations.lineup_slots"].schema[:slot].meta[:read]

    read_keys = formation.slots.map { |slot| slot_type[slot.db] }

    expect(read_keys).to eq(formation.slot_keys)
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
