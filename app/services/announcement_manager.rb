class AnnouncementManager
  attr_gtk
  attr :announcements, :completed_announcement

  def initialize
    $announcement_manager = self
    @announcements = []
    @current_announcement = nil
    @completed_announcement = false
  end

  def add_announcement(announcement)
    no_announcements = @announcements.empty? && @current_announcement == nil
    @announcements << announcement
    display_next_announcement if no_announcements
  end

  def clear_announcements_queue
    @announcements = []
    @current_announcement = nil
  end

  def tick
    @completed_announcement = false
    @current_announcement&.tick
    if @current_announcement
      if @current_announcement.message_completed?
        display_next_announcement
        @completed_announcement = true
      end
    end
  end

  def display_next_announcement
    if @announcements.empty?
      @current_announcement = nil
    else
      @current_announcement = @announcements.shift
      @current_announcement.start_message
    end
  end

  def prefab
    @current_announcement&.prefab
  end
end
