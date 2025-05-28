require_relative 'card.rb'

class IngredientCard < Card

    def calc_position num_cards, index
        x_s = ( GTK.args.grid.w / 2) - ( num_cards * ( ( @w + @padding ) / 2 ) )
        if !@grabbed

            if @selected
                # FIXME: Perform selected card lineup for crafting
            else
                # FIXME: Float around
                @f_pos.x = @f_pos.x + (Math::cos(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
                @f_pos.y = @f_pos.y + (Math::sin(@floating_seed + Kernel.tick_count * 0.01) * 0.15)
                @f_angle = Math::sin(@floating_seed + Kernel.tick_count * 0.005) * 2
            end



            @pos.x = @pos.x.lerp @f_pos.x, 0.2
            @pos.y = @pos.y.lerp @f_pos.y, 0.2
            @w = @w.lerp @fw, 0.2
            @h = @h.lerp @fh, 0.2
        else
            @f_angle = 0
        end
    
        @angle = @angle.lerp @f_angle, 0.2
  
    end

end