=begin

        RENDER STUFF
        if @matching_potion
        craftable_potion_tooltip ||= [
            {
            x: grid.w / 2,
            y: grid.h / 2,
            text: "Press SPACE BAR to finalize brew!",
            anchor_x: 0.5,
            anchor_y: 0.5,
            size_enum: 10,
            r: 255,
            },
            {
            x: grid.w / 2,
            y: grid.h / 2 + 75,
            text: "#{@matching_potion.data.name}",
            anchor_x: 0.5,
            anchor_y: 0.5,
            size_enum: 10,
            r: 255,
            }
        ]
        l3 << [ craftable_potion_tooltip ]
        end
=end