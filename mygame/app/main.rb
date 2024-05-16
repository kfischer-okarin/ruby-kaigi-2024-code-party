def tick(args)
  args.state.agents ||= 100.times.map { |i|
    direction = rand(360)
    {
      x: rand(1280), y: rand(720),
      v_x: Math.cos(direction), v_y: Math.sin(direction),
      team: i % 2
    }
  }

  agents_and_mouse = args.state.agents.dup
  agents_and_mouse << {
    x: args.inputs.mouse.x, y: args.inputs.mouse.y,
    v_x: 0, v_y: 0, team: -1
  }

  args.state.agents.each do |agent|
    agent[:x] += agent[:v_x]
    agent[:y] += agent[:v_y]
    agent[:x] += 1280 if agent[:x] < 0
    agent[:y] += 720 if agent[:y] < 0
    agent[:x] -= 1280 if agent[:x] > 1280
    agent[:y] -= 720 if agent[:y] > 720

    agents_and_mouse.each do |other|
      next if agent == other

      dx = agent[:x] - other.x
      dy = agent[:y] - other.y
      distance = Math.sqrt(dx * dx + dy * dy)

      if agent[:team] == other[:team]
        if distance < 64
          v_dx = other.v_x - agent[:v_x]
          v_dy = other.v_y - agent[:v_y]
          agent[:v_x] += v_dx * 0.1
          agent[:v_y] += v_dy * 0.1

          speed = Math.sqrt(agent[:v_x] * agent[:v_x] + agent[:v_y] * agent[:v_y])
          agent[:v_x] = agent[:v_x] / speed * 2
          agent[:v_y] = agent[:v_y] / speed * 2
        end
      else
        if distance < 64
          angle = Math.atan2(dy, dx)
          agent[:v_x] += Math.cos(angle) * 0.1
          agent[:v_y] += Math.sin(angle) * 0.1
        end
      end
    end
  end

  args.outputs.sprites << args.state.agents.map do |agent|
    angle = Math.atan2(agent[:v_y], agent[:v_x]) * (180 / Math::PI) - 90
    color = case agent[:team]
            when 0 then { r: 255, g: 0, b: 0 }
            when 1 then { r: 0, g: 200, b: 255 }
            end
    {
      x: agent[:x] - 16, y: agent[:y] - 16, w: 32, h: 32, path: 'arrow.png', angle: angle,
      **color
    }
  end

  args.outputs.debug.watch $gtk.current_framerate

  $gtk.reset seed: (Time.now.to_f * 1000) if args.inputs.keyboard.key_down.r
end

$gtk.reset
