def tick(args)
  args.state.agents ||= 100.times.map { |i|
    direction = rand(360)
    {
      x: rand(1280), y: rand(720),
      v_x: Math.cos(direction), v_y: Math.sin(direction),
      team: i % 2
    }
  }
  args.state.evil_agent ||= {
    x: rand(1280), y: rand(720),
    v_x: 1, v_y: 0, team: 2,
  }

  other_agents = args.state.agents + [args.state.evil_agent]

  args.state.agents.each do |agent|
    move_agent(agent)

    agent[:v_x] *= 1.02
    agent[:v_y] *= 1.02

    other_agents.each do |other|
      next if agent == other

      dx = agent[:x] - other.x
      dy = agent[:y] - other.y
      distance = Math.sqrt(dx * dx + dy * dy)

      if distance < 128 && agent[:team] == other.team
        v_dx = other.v_x - agent[:v_x]
        v_dy = other.v_y - agent[:v_y]

        factor = 0.1
        agent[:v_x] += v_dx * factor
        agent[:v_y] += v_dy * factor
      end

      distance_threshold = agent[:team] == other.team ? 32 : 128
      repulsion_factor = agent[:team] == other.team ? 0.2 : 0.3
      repulsion_factor = 0.5 if agent[:team] == 2
      if distance < distance_threshold
        angle = Math.atan2(dy, dx)
        agent[:v_x] += Math.cos(angle) * repulsion_factor
        agent[:v_y] += Math.sin(angle) * repulsion_factor
      end

      clamp_speed(agent, 0.5, 5)
    end
  end

  evil_agent = args.state.evil_agent
  move_agent(evil_agent)
  dx_mouse = args.inputs.mouse.x - evil_agent[:x]
  dy_mouse = args.inputs.mouse.y - evil_agent[:y]
  evil_agent.v_x += dx_mouse * 0.01
  evil_agent.v_y += dy_mouse * 0.01
  cap_speed(evil_agent, 3)


  args.outputs.sprites << args.state.agents.map { |agent| agent_sprite(agent) }
  args.outputs.sprites << agent_sprite(args.state.evil_agent)
  args.outputs.debug.watch $gtk.current_framerate

  $gtk.reset seed: (Time.now.to_f * 1000) if args.inputs.keyboard.key_down.r
end

def move_agent(agent)
  agent[:x] += agent[:v_x]
  agent[:y] += agent[:v_y]
  agent[:x] += 1280 if agent[:x] < 0
  agent[:y] += 720 if agent[:y] < 0
  agent[:x] -= 1280 if agent[:x] > 1280
  agent[:y] -= 720 if agent[:y] > 720
end

def clamp_speed(agent, min_speed, max_speed)
  speed = Math.sqrt(agent[:v_x] * agent[:v_x] + agent[:v_y] * agent[:v_y])

  if speed < min_speed
    agent[:v_x] *= min_speed / speed
    agent[:v_y] *= min_speed / speed
  elsif speed > max_speed
    agent[:v_x] *= max_speed / speed
    agent[:v_y] *= max_speed / speed
  end
end

def agent_sprite(agent)
  size = case agent[:team]
         when 2 then 64
         else 32
         end
  angle = Math.atan2(agent[:v_y], agent[:v_x]) * (180 / Math::PI) - 90
  color = case agent[:team]
          when 0 then { r: 255, g: 128, b: 0 }
          when 1 then { r: 0, g: 200, b: 255 }
          when 2 then { r: 255, g: 0, b: 0 }
          end
  {
    x: agent[:x] - size.half, y: agent[:y] - size.half, w: size, h: size, path: 'arrow.png', angle: angle,
    **color
  }
end

$gtk.reset
