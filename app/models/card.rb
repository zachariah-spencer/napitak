class Card
    attr_accessor :grabbed, :needs_removed, :pos, :f_pos, :entity_id, :w, :id, :fw, :fh, :selected, :name, :fc, :img, :padding, :pow
  
    def initialize id, entity_id, name, fc, img, pow
      @id = id
      @name = name
      @fc = fc
  
      @entity_id = entity_id
  
      @w = 160
      @h = 160
      @fw = 160
      @fh = 160
  
      @padding = -60.0
  
      @pos = {
        x: 0,
        y: 20,
      }
      @f_pos = {
        x: 0,
        y: 20,
      }
  
      @angle = 100
      @f_angle = 0
  
      @card_back_img = "sprites/card-back-purple.png"
      @img = img
      @pow = pow
      @card_composite_sprite_ref = :"card_composite_#{entity_id}"
      
      @r = 150# Numeric.rand(100..200)
      @g = 150# Numeric.rand(50..100)
      @b = 150# Numeric.rand(100..200)
  
      @grabbed = false
      @selected = false
      @needs_removed = false
      calc_render_target GTK.args
    end
  
    def calc_position num_cards, index
      x_s = ( GTK.args.grid.w / 2) - ( num_cards * ( ( @w + @padding ) / 2 ) )
      if !@grabbed
  
        @f_pos.x = x_s + (index * (@w + @padding))
  
        if !@selected
        # slight offset to x position if cards are "fanned" because the angling makes them look off-center otherwise
        @f_pos.x = x_s + (index * (@w + @padding)) - 20
          
          
          
          max_angle = -15.0  # Maximum rotation in degrees for the extreme cards
          max_y = 30
          center_index = (num_cards - 1) / 2.0
          relative_index = index - center_index
          normalized_distance = (index - center_index).abs / center_index
  
          if num_cards == 2
            @f_angle = (relative_index / center_index) * max_angle
            @f_pos.y = max_y
          elsif num_cards == 3
            @f_angle = (relative_index / center_index) * 0.75 * max_angle
            @f_pos.y = max_y * ( 1 - ( 1 * (normalized_distance)**2 )) + 25
          elsif num_cards == 4
            @f_angle = (relative_index / center_index) * max_angle
            @f_pos.y = max_y * ( 1 - ( 1.5 * (normalized_distance)**2 )) + 50
  
          elsif num_cards > 1
            # Calculate the card's rotation as a fraction of the maximum angle
            @f_angle = (relative_index / center_index) * max_angle
            @f_pos.y = max_y * ( 1 - ( 2 * (normalized_distance)**2 )) + ( 0.75 * (12.5 * num_cards)) # +  ( 2 * (normalized_distance)**3 ) ) )# LINEAR: ((1 - normalized_distance) * max_y)
  
          else
            @f_angle = 0.0
            @f_pos.y = max_y
          end
  
  
        else
          @f_pos.y = ( GTK.args.grid.h / 2 ) - ( @h / 2 )
          @f_angle = 0
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
  
    def rect
      {
        id: @entity_id,
        x: @pos.x,
        y: @pos.y,
        w: @w,
        h: @h,
        angle: @angle,
      }
    end
  
    def prefab
      {
        x: @pos.x,
        y: @pos.y,
        w: @w,
        h: @h,
        angle: @angle,
        path: @card_composite_sprite_ref,
        primitive_marker: :sprite,
      }
    end
  
    def calc_render_target args
  
      # define the dimensions of the combined sprite
      # the name of the combined sprite is :card_combo
      args.outputs[@card_composite_sprite_ref].w = 160
      args.outputs[@card_composite_sprite_ref].h = 160
    
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 0,
        y: 0,
        w: 160,
        h: 160,
        angle: 0,
        r: @r,
        g: @g,
        b: @b,
        path: @card_back_img,
      }
    
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 40,
        y: 40,
        w: 80,
        h: 80,
        angle: 0,
        path: @img,
      }
    
      # add a label in the center of the render target
      args.outputs[@card_composite_sprite_ref].primitives << {
        x: 80,
        y: 135,
        text: "#{@name}",
        anchor_x: 0.5,
        anchor_y: 0.5,
        r: 255,
        g: 255,
        b: 255,
        size_enum: 3,
      }
    
      if @fc > 0
        if @id[0] == "i"
          # add a label in the center of the render target
          args.outputs[@card_composite_sprite_ref].primitives << {
            x: 80,
            y: 20,
            text: "#{@fc}",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0,
            g: 150,
            b: 150,
            size_enum: 1,
          }
        else
          # add a label in the center of the render target
          args.outputs[@card_composite_sprite_ref].primitives << {
            x: 20,
            y: 20,
            text: "#{@fc}",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 0,
            g: 150,
            b: 150,
            size_enum: 1,
          }
  
          # add a label in the center of the render target
          args.outputs[@card_composite_sprite_ref].primitives << {
            x: 140,
            y: 20,
            text: "#{@pow}",
            anchor_x: 0.5,
            anchor_y: 0.5,
            r: 255,
            g: 255,
            b: 0,
            size_enum: 1,
          }
        end
      end
  
      args.outputs.primitives << { 
        x: 0,
        y: 0,
        w: 160,
        h: 160,
        path: @card_composite_sprite_ref,
        primitive_marker: :sprite,
      }
  
    end
  
end