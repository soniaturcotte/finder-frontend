module SupergroupFinderHelper
  def wants_different_supergroup_finder?
    binding.pry
    return false unless is_supergroup_finder

    if desired_supergroup.blank?
      params[:supergroup] = finder_slug
      return false
    end

    finder_slug != desired_supergroup
  end

  def is_supergroup_finder
    supergroups.include? finder_slug
  end

  def supergroups
    @supergroups ||= Supergroups.all.map { |g| g.value }
  end

  def desired_supergroup
    params[:supergroup]
  end

  def requested_supergroup_finder_path
    "/#{desired_supergroup}?#{params.to_query}"
  end
end
