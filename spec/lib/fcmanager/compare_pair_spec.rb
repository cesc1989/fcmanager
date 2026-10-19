# frozen_string_literal: true

RSpec.describe Fcmanager::ComparePair do
  it "toma los ids de los params si están en la plantilla" do
    params = {a: "3", b: "7"}

    pair = described_class.from_params(params, [3, 7, 9])

    expect(pair.to_params).to eq(a: 3, b: 7)
  end

  it "descarta ids no numéricos, vacíos o fuera de la plantilla, y lee en base 10" do
    allowed = [3, 10]

    pairs = [
      described_class.from_params({a: "abc", b: ""}, allowed),
      described_class.from_params({a: "99"}, allowed),
      described_class.from_params({a: "3x"}, allowed)
    ]
    leading_zero = described_class.from_params({a: "010"}, allowed)

    expect(pairs.map(&:to_params)).to eq([{}, {}, {}])
    expect(leading_zero.a).to eq(10)
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

    results = [
      empty.with(5),
      only_b.with(5),
      full.with(5),
      full.with(3)
    ]

    expect(results.map(&:to_params)).to eq(
      [
        {a: 5},
        {a: 5, b: 7},
        {a: 3, b: 5},
        {a: 3, b: 7}
      ]
    )
  end

  it "swap, without, box_of y complete?" do
    pair = described_class.new(3, 7)

    swapped = pair.swap
    without_a = pair.without(:a)

    expect(swapped.to_params).to eq(a: 7, b: 3)
    expect(without_a.to_params).to eq(b: 7)
    expect([pair.box_of(3), pair.box_of(7), pair.box_of(9)]).to eq([:a, :b, nil])
    expect([pair.complete?, without_a.complete?]).to eq([true, false])
  end
end
