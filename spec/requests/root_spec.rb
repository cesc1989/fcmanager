# frozen_string_literal: true

RSpec.describe "Root", type: :request do
  it "renders the squad list" do
    get "/"

    expect(last_response.status).to be(200)
  end
end
