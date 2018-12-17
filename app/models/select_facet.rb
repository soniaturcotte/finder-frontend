class SelectFacet < FilterableFacet
  def allowed_values
    facet['allowed_values']
  end

  def options
    [["", ""]] + allowed_values.map { |allowed_value| [allowed_value['label'], allowed_value['value']] }
  end

  def data_attributes
    {
      track_category: "filterClicked",
      track_action: key
    }
  end

  def value=(new_value)
    @value = Array(new_value)
  end

  def sentence_fragment
    return nil unless selected_values.any?

    {
      'type' => "text",
      'preposition' => preposition,
      'values' => value_fragments,
    }
  end

  def selected_option
    return nil unless selected_values.any?

    selected_values.first.values
  end

private

  def value_fragments
    selected_values.map { |v|
      {
        'label' => v['label'],
        'parameter_key' => key,
      }
    }
  end

  def selected_values
    return [] if @value.nil?

    allowed_values.select { |option|
      @value.include?(option['value'])
    }
  end
end
