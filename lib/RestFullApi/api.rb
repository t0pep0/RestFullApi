class RestFullApi::Api < ActionController::Base

  def apinize object
    if defined? object
      detect_type object
    else
      :object_not_defined
    end
    case @type
    when :model then
        Rails.logger.debug "Load model: #{object.class.to_s}\n"
        RestFullApi::Model.new object
    when :embed then
        Rails.logger.debug "Load embed: #{object.to_s}\n"
        RestFullApi::Embed.new object
    when :record then
        Rails.logger.debug "Load record: #{object.to_s}\n"
        RestFullApi::Record.new object
    else
        :unknown_object
    end
  end

  private

  def detect_type object
    if defined? object.superclass
      if defined? object.class
        case object
        when Class then
          @type = :model
        when Array then
          @type = :embed
        else
          @type = :unknown
        end
      else
        @type = :unknown
      end
    else
      if defined? Object.class.superclass
        if object.class.superclass == ActiveRecord::Base
          @type = :record
        else
          @type = :unknown
        end
      else
        @type = :unknown
      end
    end
  end

end
