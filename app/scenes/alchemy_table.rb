class AlchemyTable
  attr_gtk
  attr

  def initialize(recipe_book, max_uses:); end
  def craft_or_refresh(player, recipe_or_potion); end
  def leave_early(player); end

  def tick(); end

  def calc(); end

  def render(layer_num)
    l0 = []
    l1 = []
    l2 = []
    l3 = []
    l4 = []

    case layer_num
    when 0
      return l0
    when 1
      return l1
    when 2
      return l2
    when 3
      return l3
    when 4
      return l4
    else
      # puts "combat.rb: Invalid Render Argument"
    end
  end

end