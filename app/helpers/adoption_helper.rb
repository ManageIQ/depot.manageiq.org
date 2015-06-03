module AdoptionHelper
  #
  # Return a link to a Extension to enable/disable adoption.
  #
  # @param obj [Extension]
  #
  # @return [String] the link, wrapped in an <li>
  #
  def link_to_adoption(obj)
    if policy(obj).manage_adoption?
      txt, up = if obj.up_for_adoption?
                  ['Disable adoption', false]
                else
                  ['Put up for adoption', true]
                end

      content_tag(:li, adoption_url(obj, txt, up))
    end
  end

  private

  #
  # The actual URL to use in link_to_adoption.
  #
  # @param obj [Extension] The Extension to link to
  # @param txt [String] The text of the URL
  # @param up [Boolean] This will be True or False, depending on if adoption is
  # being enabled or disabled.
  #
  # @return [String] the URL to link to
  #
  def adoption_url(obj, txt, up)
    link_to(polymorphic_path(obj, "#{obj.class.name.downcase}" => { up_for_adoption: up }), method: :patch) do
      "<i class=\"fa fa-heart\"></i> #{txt}".html_safe
    end
  end
end
