require "spec_helper"
require "search_query_builder"

describe SearchQueryBuilder do
  subject(:queries) do
    SearchQueryBuilder.new(
      finder_content_item: finder_content_item,
      params: params,
    ).call
  end

  let(:query) { queries.first }

  let(:finder_content_item) {
    {
      'details' => {
        'facets' => facets,
        'filter' => filter,
        'reject' => reject,
        'default_order' => default_order,
        'default_documents_per_page' => nil,
      }
    }
  }

  let(:facets) { [] }
  let(:filter) { {} }
  let(:reject) { {} }
  let(:default_order) { nil }

  let(:params) { {} }

  it "should include a count" do
    expect(query).to include("count" => 1500)
  end

  context "with pagination" do
    let(:finder_content_item) {
      {
        'details' => {
          'facets' => facets,
          'filter' => filter,
          'reject' => reject,
          'default_order' => default_order,
          'default_documents_per_page' => 10
        }
      }
    }

    it "should use documents_per_page from content item" do
      expect(query).to include(
        "count" => 10,
        "start" => 0
      )
    end
  end

  context "without any facets" do
    it "should include base return fields" do
      expect(query).to include(
        "fields" => "title,link,description,public_timestamp",
      )
    end
  end

  context "with facets" do
    let(:facets) {
      [
        {
          'key' => "alpha",
          'filterable' => false,
        },
        {
          'key' => "beta",
          'filterable' => false,
        },
      ]
    }

    let(:reject) {
      {
        alpha: "value"
      }
    }

    it "should include base and extra return fields" do
      expect(query).to include(
        "fields" => "title,link,description,public_timestamp,alpha,beta",
      )
    end

    it "should include reject fields prefixed with reject_" do
      expect(query).to include(
        "reject_alpha" => "value",
      )
    end

    context "facets with filter_keys" do
      before do
        facets.first["filter_key"] = "zeta"
      end

      it "should use the filter value in fields" do
        expect(query).to include(
          "fields" => "title,link,description,public_timestamp,zeta,beta",
        )
      end
    end

    context "facets with or combine_mode" do
      before do
        facets.first["filterable"] = true
        facets.first["type"] = "text"

        facets.second["filterable"] = true
        facets.second["type"] = "text"
        facets.second["combine_mode"] = "or"
      end

      let(:params) do
        {
          "alpha" => "test",
          "beta" => "test",
        }
      end

      it "should generate two queries" do
        expect(queries.count).to eq(2)
      end

      it "should filter on just alpha in the first query" do
        expect(queries.first["filter_alpha"]).to eq(%w(test))
        expect(queries.first["filter_beta"]).to be_nil
      end

      it "should filter on both alpha and beta in the second query" do
        expect(queries.second["filter_alpha"]).to be_nil
        expect(queries.second["filter_beta"]).to eq(%w(test))
      end
    end
  end

  context "without keywords" do
    it "should not include a keyword query" do
      expect(query).not_to include("q")
    end

    it "should include an order query" do
      expect(query).to include("order" => "-public_timestamp")
    end

    context "with a custom order" do
      let(:default_order) { "custom_field" }

      it "should include a custom order query" do
        expect(query).to include("order" => "custom_field")
      end
    end
  end

  context "with keywords" do
    let(:params) {
      {
        "keywords" => "mangoes",
      }
    }

    it "should include a keyword query" do
      expect(query).to include("q" => "mangoes")
    end

    it "should not include an order query" do
      expect(query).not_to include("order")
    end
  end

  context "with a base filter" do
    let(:filter) { { "document_type" => "news_story" } }

    it "should include fields prefixed with filter_" do
      expect(query).to include("filter_document_type" => "news_story")
    end
  end

  describe '#start' do
    it 'starts at zero by default' do
      query = query_with_params({})

      expect(query['start']).to eql(0)
    end

    it 'starts at zero when page param is zero' do
      query = query_with_params("page" => 0)

      expect(query['start']).to eql(0)
    end

    it 'starts at zero when page param is nil' do
      query = query_with_params("page" => nil)

      expect(query['start']).to eql(0)
    end

    it 'starts at zero when page param is empty' do
      query = query_with_params("page" => "")

      expect(query['start']).to eql(0)
    end

    it 'is paginated' do
      query = query_with_params("page" => "10")

      expect(query['start']).to eql(13500)
    end

    def query_with_params(params)
      SearchQueryBuilder.new(
        finder_content_item: finder_content_item,
        params: params
      ).call.first
    end
  end
end
