class TutorialService
  attr_gtk

  def initialize(files:, encounter_manager:, enemy:)
    @files = files
    @encounter_manager = encounter_manager
    @enemy = enemy
  end

  def handle_combat_start
    tutorials = @files.save_data["tutorials"] ||= {}
    if @encounter_manager.combats_won == 0 && !tutorials["fleeing"]
      tutorials["fleeing"] = true
      announce_tutorial(24, x: 900, y: 50)
      announce_tutorial(25, x: 900, y: 50)
    end

    enemy_stats = @enemy.combat_stats
    if !(enemy_stats.vulnerabilities + enemy_stats.resistances).empty? &&
         @encounter_manager.combats_won >= 1 && !tutorials["damage_types"]
      tutorials["damage_types"] = true
      announce_tutorial(26, x: 900, y: 50)

      details_text = ""
      unless enemy_stats.vulnerabilities.empty?
        list = format_damage_list(enemy_stats.vulnerabilities)
        details_text += " The #{@enemy.name} is vulnerable to #{list}"
      end
      unless enemy_stats.resistances.empty?
        list = format_damage_list(enemy_stats.resistances)
        details_text += " The #{@enemy.name} is resistant to #{list}"
      end
      GameUtils.announce(text: details_text, duration: 6.5.seconds, tutorial_id: 26, x: 900, y: 50)
      announce_tutorial(29, x: 900, y: 50)
    end
  end

  private

  def announce_tutorial(index, x:, y:)
    $TUTORIAL_INDEX = index
    id, text = GameUtils.tutorial_string?(index)
    GameUtils.announce(text: text, duration: 6.5.seconds, tutorial_id: id, x: x, y: y)
  end

  def format_damage_list(list)
    names = list.map { |v| $DAMAGE_TYPE_NAMES[v] }

    case names.length
    when 0
      ""
    when 1
      "#{names.first}."
    when 2
      "#{names.first} and #{names.last}."
    else
      "#{names[0..-2].join(', ')}, and #{names.last}."
    end
  end
end
