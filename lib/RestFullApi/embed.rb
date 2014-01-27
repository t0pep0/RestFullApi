class RestFullApi::Embed

  def initialize embed
    @embed = embed
    @api_attr_readable = embed.api_attr_readable
    @epi_embed_readable = embed.api_embed_readable
    @options = get_params
    prepare_hash @embed
    send_answer
  end

  def get_embed_attr_readable object
    object.api_embed_readable
  end

end
