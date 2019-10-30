module Errors
  def error_response(errors, status)
    # data = errors.map { |error| "#{controller_namespace}.#{error}" }
    json_response({ errors: errors }, status)
  end

  def error_code(data)
    class_name = data.class.name.underscore.split('/').last
    data.errors.messages.values.flatten.collect{ |err_msg| "#{class_name}.#{err_msg}" }
  end

  def controller_namespace
    self.class.parent.name.split('::').last.underscore
  end

  def record_not_found(error)
    class_name = error.model.underscore.split('/').last
    json_response({ errors: ["#{controller_namespace}.#{class_name}.not_found"] }, 404)
  end
end
