class AnnouncementManager
  attr_gtk
  attr :announcements, :completed_announcement, :current_announcement

  def initialize
    $announcement_manager = self
    @announcements = []
    @current_announcement = nil
    @completed_announcement = false
  end

  def current_announcement_id?
    @current_announcement&.tutorial_id || -1
  end

  def add_announcement(announcement)
    was_no_announcements = no_announcements?
    @announcements << announcement
    display_next_announcement if was_no_announcements
  end

  def no_announcements?
    @announcements.empty? && @current_announcement.nil?
  end

  def clear_announcements_queue
    @announcements = []
    @current_announcement = nil
  end

  def tick
    @completed_announcement = false
    @current_announcement&.tick
    if @current_announcement
      # created_tick.elapsed_time check prevents a race condition for many click skip events
      if @current_announcement.message_completed? || GTK.args.inputs.mouse.click && @current_announcement.created_tick.elapsed_time >= 1
        display_next_announcement
        @completed_announcement = true
      end
    end
  end

  def display_next_announcement
    if @announcements.empty?
      @current_announcement = nil
      #$game.input_locked = false
    else
      @current_announcement = @announcements.shift
      @current_announcement.start_message
      #$game.input_locked = true
    end
  end

  def prefab
    @current_announcement&.prefab
  end
end
