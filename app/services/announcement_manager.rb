class AnnouncementManager
  attr_gtk
  attr :announcements

  def initialize
    $announcement_manager = self
    @announcements = []
    @current_announcement = nil
  end

  def add_announcement(announcement)
    announcements_was_empty = @announcements.empty?
    @announcements << announcement
    display_next_announcement if announcements_was_empty
  end

  def tick
    @announcements.each { |a| puts "#{a.text}"}
    @current_announcement&.tick
    if @current_announcement
      display_next_announcement if @current_announcement.message_completed?
    end
  end

  def display_next_announcement
    @current_announcement = @announcements.shift if !@announcements.empty?
    @current_announcement&.start_message
  end

  def prefab
    @current_announcement.prefab
  end
end
