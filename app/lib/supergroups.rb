class Supergroups
  # These are from govuk_document_types/data/supertypes.yml
  CONTENT_PURPOSE_SUPERGROUPS = %w(
    news_and_communications
    services
    guidance_and_regulation
    policy_and_engagement
    research_and_statistics
    transparency
  )

  def self.all
    lookup(CONTENT_PURPOSE_SUPERGROUPS)
  end

  def self.lookup(keys)
    raise_not_found(nil) unless keys
    keys = [keys] if keys.is_a?(String)
    groups = GovukDocumentTypes.supergroups(ids: keys)
    raise_not_found(keys) if groups.empty?
    groups.map { |g| Supergroup.new(g) }
  end

  def self.raise_not_found(keys)
    msg = "Supergroup not found for keys: '#{keys}'."
    raise Supergroups::NotFound.new(msg)
  end

  class Supergroup
    attr_reader :label, :value, :subgroups

    def initialize(hash)
      @value = hash["id"]
      @label = I18n.t(hash['id'], scope: 'content_purpose_supergroup', default: hash['id'].humanize)
      @subgroups = hash["subgroups"]
    end

    def to_h
      {
        "label" => label,
        "value" => value,
        "subgroups" => subgroups_as_hash
      }
    end

    def subgroups_as_hash
      subgroups.map do |subgroup|
        {
          'label' => I18n.t(subgroup, scope: 'content_purpose_subgroup', default: subgroup.humanize),
          'value' => subgroup,
        }
      end
    end
  end

  class NotFound < StandardError; end
end
