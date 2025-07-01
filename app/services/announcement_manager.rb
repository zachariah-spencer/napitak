class AnnouncementManager
  attr_gtk
  attr :announcements

  def initialize
    $announcement_manager = self
    @announcements = []
    @current_announcement = nil
  end

  def add_announcement(announcement)
    no_announcements = @announcements.empty? && @current_announcement == nil
    @announcements << announcement
    display_next_announcement if no_announcements
  end

  def current_announcement_invalid?
    @current_announcement == nil || @current_announcement.message_completed?
  end

  def tick
    puts "ANNOUNCEMENTS LIST:\n#{@announcements}\n\n CURRENT ANNOUNCEMENT: #{@current_announcement}"
    @current_announcement&.tick
    if @current_announcement
      display_next_announcement if @current_announcement.message_completed?
    end
  end

  def display_next_announcement
    puts "HERE"
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
