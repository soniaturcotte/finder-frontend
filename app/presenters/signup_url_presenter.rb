class SignupUrlPresenter
  def initialize(content_item, view_context)
    @content_item = content_item
    @view_context = view_context
  end

  def url
    @url ||= calculate_url
  end

  private
    attr_reader :content_item, :view_context

    def calculate_url
      view_context.email_alert_subscriptions_path(hidden_params: clean_filtered_params)
    end

    def clean_filtered_params
      @filter_hidden_params ||= begin
        ParamsCleaner
            .new(filtered_params)
            .cleaned
            .delete_if { |_, value| value.blank? }
      end
    end

    def filtered_params
      facet_choices = content_item['details']['email_filter_facets'].reject { |facet| facet.has_key?("facet_choices") }
      params = view_context.params.to_unsafe_hash
      filtered_params = {}
      facet_choices.each do |facet_choice|
        key = facet_choice["facet_name"]
        if params.has_key?(key)
          translated_filter_key = facet_choice["filter_key"] || key
          filtered_params[translated_filter_key] = params[key]
        end
      end
      filtered_params
    end
end
