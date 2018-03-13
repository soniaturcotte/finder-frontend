class AdvancedSearchFinderApi < FinderApi
  TAXON_SEARCH_FILTER = "taxons".freeze

  attr_reader :content_item

  def content_item_with_search_results
    filter_params[TAXON_SEARCH_FILTER] = taxon["content_id"]

    content_item = fetch_content_item
    search_response = fetch_search_response(content_item)
    content_item = augment_content_item_links_with_taxon(content_item, taxon)
    augment_content_item_with_results(content_item, search_response)
  end

  def taxon
    @taxon ||= Services.content_store.content_item(filter_params[TAXON_SEARCH_FILTER])
  rescue GdsApi::ContentStore::ItemNotFound
    filter_params.delete(TAXON_SEARCH_FILTER)
    nil
  end

private

  def augment_content_item_links_with_taxon(content_item, taxon)
    content_item["links"]["taxons"] = [taxon]
    content_item
  end

  def augment_facets_with_dynamic_values(content_item, _)
    augment_facets_with_dynamic_subgroups(content_item) if supergroups.any?
  end

  def augment_facets_with_dynamic_subgroups(content_item)
    subgroups = supergroups.map(&:subgroups_as_hash).flatten
    facet = find_facet(content_item, "content_purpose_subgroup")
    return unless facet
    facet["allowed_values"] = subgroups
    facet["type"] = "hidden" if subgroups.size < 2
  end

  def supergroups
    Supergroups.lookup(filter_params["content_purpose_supergroup"])
  end

  def find_facet(content_item, key)
    content_item["details"]["facets"].find { |f| f["key"] == key }
  end
end
