class Scene
  attr :sc_id
  attr_gtk

  def tick
  end

  def render(_layer_num)
  end

  def ready
  end

  def cleanup
    $encounter_manager.inc_encounters_completed
  end
end
