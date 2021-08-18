class ParamMustBePresentError < StandardError
  def initialize(param)
    super("Params must be present: #{param}!")
  end
end

