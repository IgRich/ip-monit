class IpAction < Sequel::Model(DbConnection.connect[:ip_actions])
  STATES = { new: 0, performed: 1 }.freeze
  ACTIONS = { create: 0, delete: 1 }.freeze

  def before_create
    self.state ||= STATES[:new]
    self.created_at ||= Time.now
    self.updated_at ||= self.created_at
    super
  end

  def before_save
    self.updated_at = Time.now
    super
  end
end