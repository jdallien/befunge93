#!/usr/bin/env ruby
# Befunge-93 interpreter for Ruby Quiz #184
# Jeff Dallien (jeff @ dallien.net)
#
class Stack
  attr_reader :stack

  def initialize
    @stack = []
  end

  def pop
    return 0 if @stack.empty?
    @stack.pop
  end

  def push(value)
    @stack.push(value)
  end

  def swap!
    first  = pop
    second = pop
    push(first)
    push(second)
  end

  def dup!
    top = pop
    push(top)
    push(top)
  end
end

class Instruction
  attr_reader :value

  def initialize(value)
    @value = value
  end

  # digits 0-9
  def value_for_stack?
    (@value[0] >= 48 && @value[0] <= 57)
  end

  # " (double quote) toggles string mode
  def string_mode_toggle?
    (34 == @value[0])
  end
end

class ProgramCounter
  attr_reader :x
  attr_reader :y
  attr_accessor :direction

  def initialize
    @x = 0
    @y = 0
    @direction = :right
  end

  def move!
    send("move_#{@direction}!")
  end

  private

  def move_right!
    @x = (@x + 1) % 80
  end

  def move_left!
    @x = (@x - 1) % 80
  end

  def move_down!
    @y = (@y + 1) % 25
  end

  def move_up!
    @y = (@y - 1) % 25
  end
end

class BefungeProgram
  def initialize
    @program = []
  end

  def load_from_file(filename)
    File.open(filename) do |f|
      25.times do
        add_program_line(f.gets.to_s)
      end
    end
  end

  def [](index)
    @program[index]
  end

  def load_from_string_array(program_strings)
    25.times do |index|
      add_program_line(program_strings[index].to_s)
    end
  end

  private

  def add_program_line(line)
    padded_line = line.chomp[0..80].ljust(80)
    @program << padded_line.split('').map { |c| c[0] }
  end
end


class Befunger
  INSTRUCTION_TABLE = { '@'  => :exit,
                        ' '  => :blank,
                        '\\' => :swap,
                        ':'  => :dup,
                        '$'  => :pop,
                        ','  => :output_ascii,
                        '.'  => :output_int,
                        '+'  => :add,
                        '-'  => :subtract,
                        '*'  => :multiply,
                        '/'  => :divide,
                        '%'  => :mod,
                        '!'  => :not,
                        '`'  => :greater,
                        '>'  => :pc_right,
                        '<'  => :pc_left,
                        '^'  => :pc_up,
                        'v'  => :pc_down,
                        '?'  => :pc_random,
                        '_'  => :horizontal_if,
                        '|'  => :vertical_if,
                        'g'  => :get,
                        'p'  => :put,
                        '&'  => :input_value,
                        '~'  => :input_character,
                        '#'  => :bridge,
                        '"'  => :toggle_string_mode
                      }


  def initialize(program)
    @program     = program
    @pc          = ProgramCounter.new
    @stack       = Stack.new
    @exit_called = false
    @string_mode = false
  end

  def run
    until @exit_called
      execute_instruction
      @pc.move!
    end
  end

  private

  # used so that output can be captured during testing
  def output(value)
    print value
    STDOUT.flush
  end

  def read_instruction
    Instruction.new(@program[@pc.y][@pc.x].chr)
  end

  def execute_instruction
    instruction = read_instruction

    if @string_mode && !instruction.string_mode_toggle?
      @stack.push(instruction.value[0])
    elsif instruction.value_for_stack?
      @stack.push(instruction.value.to_i)
    else
      begin
        send(INSTRUCTION_TABLE[instruction.value])
      rescue TypeError, NoMethodError
        raise "Unknown instruction: #{instruction.inspect}"
      end
    end
  end

  def exit
    @exit_called = true
  end

  def blank
  end

  def swap
    @stack.swap!
  end

  def dup
    @stack.dup!
  end

  def pop
    @stack.pop
  end

  def output_ascii
    value = @stack.pop
    output value.chr
  end

  def output_int
    value = @stack.pop
    output "#{value.to_i} "
  end

  def generic_math_instruction(operation)
    rhs = @stack.pop
    lhs = @stack.pop
    result = lhs.send(operation, rhs)
    @stack.push(result)
  end

  def add
    generic_math_instruction('+')
  end

  def subtract
    generic_math_instruction('-')
  end

  def divide
    generic_math_instruction('/')
  end

  def mod
    generic_math_instruction('%')
  end

  def multiply
    generic_math_instruction('*')
  end

  def not
    value = @stack.pop
    result = (value == 0) ? 1 : 0
    @stack.push(result)
  end

  def greater
    rhs = @stack.pop
    lhs = @stack.pop
    result = (lhs > rhs) ? 1 : 0
    @stack.push(result)
  end

  def pc_right
    @pc.direction = :right
  end

  def pc_left
    @pc.direction = :left
  end

  def pc_up
    @pc.direction = :up
  end

  def pc_down
    @pc.direction = :down
  end

  def pc_random
    directions = [:right, :left, :up, :down]
    @pc.direction = directions[rand(4)]
  end

  def horizontal_if
    value = @stack.pop
    @pc.direction = (value == 0) ? :right : :left
  end

  def vertical_if
    value = @stack.pop
    @pc.direction = (value == 0) ? :down : :up
  end

  def get
    y = @stack.pop
    x = @stack.pop
    @stack.push(@program[y][x])
  end

  def put
    y = @stack.pop
    x = @stack.pop
    @program[y][x] = @stack.pop
  end

  def input_value
    input = $stdin.gets.to_i
    @stack.push(input)
  end

  def input_character
    input_char = $stdin.gets[0]
    @stack.push(input_char)
  end

  def bridge
    @pc.move!
  end

  def toggle_string_mode
    @string_mode = !@string_mode
  end
end

if $0 == __FILE__
  if ARGV[0]
    program  = BefungeProgram.new
    program.load_from_file(ARGV[0])
    befunger = Befunger.new(program)
    befunger.run
  else
    puts "Usage: ruby befunge.rb program.bf"
  end
end


