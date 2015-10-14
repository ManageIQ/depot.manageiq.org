module ExtensionsHelper
  #
  # Returns a URL for the latest version of the given extension
  #
  # @param extension [Extension]
  #
  # @return [String] the URL
  #
  def latest_extension_version_url(extension)
    api_v1_extension_version_url(
      extension, extension.latest_extension_version
    )
  end

  #
  # Show the contingent extension name and version
  #
  # @param contingent [ExtensionDependency]
  #
  # @return [String] the link to the contingent extension
  #
  def contingent_link(dependency)
    version = dependency.extension_version
    extension = version.extension
    txt = "#{extension.name} #{version.version}"
    link_to(txt, owner_scoped_extension_url(extension))
  end

  #
  # If we have a linked extension for this dependency, allow the user to get to
  # it. Otherwise, just show the name
  #
  # @param dep [ExtensionDependency]
  #
  # @return [String] The dependency info to show on the page
  #
  def dependency_link(dep)
    name_and_version = "#{dep.name} #{dep.version_constraint}"

    content_tag(:td) do
      if dep.extension
        link_to name_and_version, owner_scoped_extension_url(dep.extension), rel: 'extension_dependency'
      else
        name_and_version
      end
    end
  end

  #
  # Return the correct state for an extension follow/unfollow button. If given a
  # block, the result of the block will become the button's text.
  #
  # @example
  #   <%= follow_button_for(@extension) %>
  #   <%= follow_button_for(@extension) do |following| %>
  #     <%= following ? 'Stop Following' : 'Follow' %>
  #   <% end %>
  #
  # @param extension [Extension] the Extension to follow or unfollow
  # @param params [Hash] any additional query params to add to the follow button
  # @yieldparam following [Boolean] whether or not the +current_user+ is
  #   following the given +Extension+
  #
  # @return [String] a link based on the following state for the current extension.
  #
  def follow_button_for(extension, params = {}, &block)
    fa_icon = content_tag(:i, '', class: 'fa fa-star')
    followers_count = extension.extension_followers_count.to_s
    followers_count_span = content_tag(
      :span,
      number_with_delimiter(followers_count),
      class: 'extension_follow_count'
    )
    follow_html = fa_icon + 'Star' + followers_count_span
    unfollow_html = fa_icon + 'Unstar' + followers_count_span

    unless current_user
      return link_to(
        follow_extension_path(extension, params.merge(username: extension.owner_name)),
        method: 'put',
        rel: 'sign-in-to-follow',
        class: 'button radius tiny follow',
        title: 'You must be signed in to star an extension.',
        'data-tooltip' => true
      ) do
        if block
          block.call(false)
        else
          follow_html
        end
      end
    end

    if extension.followed_by?(current_user)
      link_to(
        unfollow_extension_path(extension, params.merge(username: extension.owner_name)),
        method: 'delete',
        rel: 'unfollow',
        class: 'button radius tiny follow',
        id: 'unfollow_extension',
        'data-extension' => extension.name,
        remote: true
      ) do
        if block
          block.call(true)
        else
          unfollow_html
        end
      end
    else
      link_to(
        follow_extension_path(extension, params.merge(username: extension.owner_name)),
        method: 'put',
        rel: 'follow',
        class: 'button radius tiny follow',
        id: 'follow_extension',
        'data-extension' => extension.name,
        remote: true
      ) do
        if block
          block.call(false)
        else
          follow_html
        end
      end
    end
  end

  #
  # Generates a link to the current page with a parameter to sort extensions in
  # a particular way.
  #
  # @param linked_text [String] the contents of the +a+ tag
  # @param ordering [String] the name of the ordering
  #
  # @example
  #   link_to_sorted_extensions 'Recently Updated', 'recently_updated'
  #
  # @return [String] the generated anchor tag
  #
  def link_to_sorted_extensions(linked_text, ordering)
    if params[:order] == ordering
      link_to linked_text, params.except(:order), class: 'button radius secondary active'
    else
      link_to linked_text, params.merge(order: ordering), class: 'button radius secondary'
    end
  end
end
