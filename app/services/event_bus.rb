class EventBus
  def initialize
    $event_bus = self
    @listeners = Hash.new { |h, k| h[k] = [] }
  end

  def subscribe(event_name, owner = nil, &block)
    @listeners[event_name] << { owner: owner, block: block }
  end

  def publish(event_name, payload = {})
    return unless @listeners[event_name]
    @listeners[event_name].each { |l| l[:block].call(payload) }
  end

  def unsubscribe_owner(owner)
    @listeners.each_value { |arr| arr.reject! { |h| h[:owner] == owner } }
  end
end
