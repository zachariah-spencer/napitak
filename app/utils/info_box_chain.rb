class InfoBoxChain
  def initialize(groups)
    # each element of groups can be:
    #  • a Hash → single box
    #  • an Array of Hashes → multiple boxes to show in parallel
    @groups      = groups.dup
    @current_ids = []
    @cancelled   = false
    start_next_group
  end

  # cancel the rest of the chain and stop any active boxes
  def cancel
    @cancelled = true
    @current_ids.each { |id| InfoBox.stop_by_id(id) }
    @current_ids.clear
  end

  private

  # fire the next group (one or many) unless cancelled or done
  def start_next_group
    return if @cancelled || @groups.empty?

    group = @groups.shift
    defs  = group.is_a?(Array) ? group : [group]

    # how many in this group; when all complete, we advance
    @remaining = defs.size
    @current_ids = []

    defs.each do |opts|
      # give each box its own on_complete
      id = InfoBox.new(**opts.merge(
        on_complete: -> {
          @remaining -= 1
          start_next_group if @remaining.zero?
        }
      )).id
      @current_ids << id
    end
  end
end
