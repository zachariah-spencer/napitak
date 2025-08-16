module RunOnce
  def run_once(key, &block)
    @__ran_once_flags__ ||= {}
    return if @__ran_once_flags__[key]
    @__ran_once_flags__[key] = true
    block.call
  end
end