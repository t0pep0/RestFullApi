class << ActiveRecord::Base

  def api_attr_readable *attrs
    if attrs.present?
      @api_attr_readable = attrs
    else
      @api_attr_readable.present? ? @api_attr_readable : []
    end
  end

  def api_embed_readable *embeds
    if embeds.present?
      @api_embed_readable = embeds
    else
      @api_embed_readable.present? ? @api_embed_readable : []
    end
  end

end
