class FinderPresenter
  include ActionView::Helpers::UrlHelper

  attr_reader :name, :slug, :organisations, :keywords

  delegate :beta_message,
           :document_noun,
           :human_readable_finder_format,
           :filter,
           :summary,
           to: :"content_item.details"

  def initialize(content_item, values = {}, keywords = nil)
    @content_item = content_item
    @name = content_item.title
    @slug = content_item.base_path
    @organisations = content_item.links.organisations
    facets.values = values
    @keywords = keywords
  end

  def beta?
    content_item.details.beta
  end

  def email_alert_signup
    if content_item.links.email_alert_signup
      content_item.links.email_alert_signup.first
    else
      nil
    end
  end

  def email_alert_signup_url
    if content_item.details.signup_link.present?
      content_item.details.signup_link
    else
      if email_alert_signup
        email_alert_signup.web_url
      end
    end
  end

  def facets
    @facets ||= FacetCollection.new(
      content_item.details.facets.map { |facet|
        FacetParser.parse(facet)
      }
    )
  end

  def filters
    facets.filters
  end

  def government?
    slug.starts_with?("/government")
  end

  def government_content_section
    slug.split('/')[2]
  end

  def metadata
    facets.metadata
  end

  def date_metadata_keys
    metadata.select{ |f| f.type == "date" }.map(&:key)
  end

  def text_metadata_keys
    metadata.select{ |f| f.type == "text" }.map(&:key)
  end

  def filter_sentence_fragments
    filters.map(&:sentence_fragment).compact
  end

  def facet_keys
    facets.to_a.map(&:key)
  end

  def show_summaries?
    content_item.details.show_summaries
  end

  def page_metadata
    metadata = {
      part_of: part_of,
      from: from,
      other: other,
    }

    metadata.reject { |_, links| links.blank? }
  end

  def related
    content_item.links.related
  end

  def results
    @results ||= ResultSet.get(
      self,
      search_params,
    )
  end

  def label_for_metadata_key(key)
    facet = metadata.find { |f| f.key == key }

    facet.short_name || facet.key.humanize
  end

private
  attr_reader :content_item, :values

  def part_of
    content_item.links.part_of || []
  end

  def organisations
    content_item.links.organisations || []
  end

  def people
    content_item.links.people || []
  end

  def from
    organisations + people
  end

  def other
    if applicable_nations_html_fragment
      { "Applies to" => applicable_nations_html_fragment }
    end
  end

  def applicable_nations_html_fragment
    nation_applicability = content_item.details.nation_applicability
    if nation_applicability
      applies_to = nation_applicability.applies_to.map(&:titlecase)
      alternative_policies = nation_applicability.alternative_policies.map do |alternative|
        link_to(alternative.nation.titlecase, alternative.alt_policy_url, ({rel: 'external'} if is_external?(alternative.alt_policy_url)))
      end
      if alternative_policies.any?
        "#{applies_to.to_sentence} (see policy for #{alternative_policies.to_sentence})".html_safe
      else
        applies_to.to_sentence
      end
    end
  end

  def is_external?(href)
    if host = URI.parse(href).host
      "www.gov.uk" != host
    end
  end

  def facet_search_params
    facets.values
  end

  def keyword_search_params
    if keywords
      { "keywords" => keywords }
    else
      {}
    end
  end

  def search_params
    facet_search_params.merge(keyword_search_params)
  end
end
