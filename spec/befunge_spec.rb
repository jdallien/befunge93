require File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib', 'befunge.rb'))

describe Stack, "popping a value" do
  before :each do
    @it = Stack.new
  end

  it "should return a zero when attempting to pop from an empty stack" do
    @it.pop.should == 0
  end
end

describe Befunger, "processing instructions" do
  before :each do
    @output  = ''
    @stack   = Stack.new
    @pc      = ProgramCounter.new
    @program = BefungeProgram.new
    ProgramCounter.should_receive(:new).and_return(@pc)
    Stack.should_receive(:new).and_return(@stack)
  end

  def run_program(program_strings)
    @program.load_from_string_array(program_strings)
    processor = Befunger.new(@program)
    processor.should_receive(:output).any_number_of_times { |o| @output << o }
    processor.run
  end

  describe "blank instruction" do
    before :each do
      run_program(["   @",
                   "111@",
                   "@@@@"])
    end

    it "should not add any value the stack" do
      @stack.pop.should == 0
    end

    it "should not change the program counter direction" do
      @pc.direction.should == :right
    end
  end

  describe "an unknown instruction" do
    it "should raise an error" do
      lambda { run_program(["=@"]) }.should raise_error(/Unknown instruction/)
    end
  end

  describe "add instruction" do
    before :each do
      run_program(["12+@"])
    end

    it "should put the result of the addition on the stack" do
     @stack.pop.should == 3
    end
  end

  describe "substract instruction" do
    describe "with a positive result" do
      before :each do
        run_program(["65-@"])
      end

      it "should put the correct result on the stack" do
        @stack.pop.should == 1
      end
    end

    describe "with a negative result" do
      before :each do
        run_program(["56-@"])
      end

      it "should put the correct result on the stack" do
        @stack.pop.should == -1
      end
    end
  end

  describe "multiplication instruction" do
    before :each do
      run_program(["55*@"])
    end

    it "should put the correct result on the stack" do
      @stack.pop.should == 25
    end
  end

  describe "mod instruction" do
    describe "calculating with positive numbers" do
      before :each do
        run_program(["52%@"])
      end

      it "should put the correct value on the stack" do
        @stack.pop.should == 1
      end
    end

    describe "calculating with a negative number" do
      before :each do
        run_program(["1-2*3%@"])
      end

      it "should put the correct value on the stack" do
        @stack.pop.should == 1
      end
    end
  end

  describe "division instruction" do
    describe "calculating with positive numbers" do
      before :each do
        run_program(["93/@"])
      end

      it "should put the correct value on the stack" do
        @stack.pop.should == 3
      end
    end

    describe "calculating with negative numbers" do
      before :each do
        run_program(["3-2/@"])
      end

      it "should put the correct negative value on the stack" do
        @stack.pop.should == -2
      end
    end
  end

  describe "swap instruction" do
    before :each do
      run_program(["123\\@"])
    end

    it "should swap the two top values of the stack" do
      @stack.pop.should == 2
      @stack.pop.should == 3
    end

    it "should not change the anything below the top two values" do
      @stack.pop
      @stack.pop
      @stack.pop.should == 1
    end
  end

  describe "duplication instruction" do
    before :each do
      run_program(["1:@"])
    end

    it "should put two copies of the value on the stack" do
      @stack.pop.should == 1
      @stack.pop.should == 1
    end
  end

  describe "pop instruction" do
    before :each do
      run_program(["123$@"])
    end

    it "should remove a value from the stack" do
      @stack.pop.should == 2
      @stack.pop.should == 1
    end

    it "should not output anything" do
      @output.should == ''
    end
  end

  describe "not instruction" do
    describe "with a 0 on the top of the stack" do
      before :each do
        run_program(["0!@"])
      end

      it "should put a 1 on top of the stack" do
        @stack.pop.should == 1
      end
   end

   describe "with a non-zero value on the top of the stack" do
     before :each do
       run_program(["1!@"])
     end

     it "should put a 0 on top of the stack" do
       @stack.pop.should == 0
     end
   end
  end

  describe "greater instruction" do
    describe "with the larger value placed on the stack first" do
      before :each do
        run_program(["52`@"])
      end

      it "should place a 1 on the top of the stack" do
        @stack.pop.should == 1
      end

      it "should remove the compared values from the stack" do
        @stack.pop
        @stack.pop.should == 0
      end
    end

    describe "with the smaller value placed on the stack first" do
      before :each do
        run_program(["38`@"])
      end

      it "should put a 0 on the top of the stack" do
        @stack.pop.should == 0
      end
    end

    describe "comparing the same value" do
      before :each do
        run_program(["44`@"])
      end

      it "should place a 0 on the top of the stack" do
        @stack.pop.should == 0
      end
    end
  end


  describe "bridge instruction" do
    before :each do
      run_program(["123#...@"])
    end

    it "should skip the next instruction" do
      @output.should == "3 2 "
    end

    it "should leave remaining values on the stack" do
      @stack.pop.should == 1
    end
  end

  describe "ASCII output instruction" do
    before :each do
      run_program(["665+*1-,@"])
    end

    it "should output the ASCII character of the value on the top of the stack" do
      @output.should == "A"
    end
  end

  describe "integer output instruction" do
    before :each do
      run_program(["665+*1-.@"])
    end

    it "should output the integer on the top of the stack, followed by a space" do
      @output.should == "65 "
    end
  end

  describe "string mode" do
    before :each do
      run_program(["\"Ab\"@"])
    end

    it "should place the ASCII values on the stack" do
      @stack.pop.should == 98
      @stack.pop.should == 65
    end
  end

  describe "get instruction" do
    describe "getting a value from within the given program" do
      before :each do
        run_program(["11g@",
                     " *   "])
      end

      it "should get the value from the program and put it on the stack" do
        @stack.pop.should == '*'[0]
      end
    end

    describe "getting a value outside the given program but in the program space" do
      before :each do
        run_program(["88g@"])
      end

      it "should put the ASCII value of the space character (32) on the stack" do
        @stack.pop.should == 32
      end
    end

    describe "attempting to get a value outside the 80x25 program space" do
      it "should raise an error" do
       lambda { run_program(["066*g@"]) }.should raise_error
      end
    end
  end

  describe "put instruction" do
    describe "within the 80x25 program space" do
      before :each do
        run_program(["522p@"])
      end

      it "should put the correct value inside the program space" do
        @program[2][2].should == 5
      end
    end

    describe "outside the 80x25 program space" do
      it "should raise an error" do
        lambda { run_program(["1188*p@"]) }.should raise_error
      end
    end
  end

  describe "horizontal if instruction" do
    def horizontal_if_program(stack_value)
      run_program(["#{stack_value}          v             @ ",
                                '@,,,,"left"_"thgir",,,,, @ ',
                                '           @               '])
    end

    describe "with a zero on top of the stack" do
      before :each do
        horizontal_if_program('0')
      end

      it "should move the program counter to the right" do
        @output.should == "right"
      end
    end

    describe "with a non-zero value on top of the stack" do
      before :each do
        horizontal_if_program('4')
      end

      it "should move the program counter to the left" do
        @output.should == "left"
      end
    end
  end

  describe "vertical if instruction" do
    def vertical_if_program(stack_value)
      run_program(["#{stack_value}           |@",
                                '            5 ',
                                '            @ ',
                                '            4 '])
    end

    describe "with a zero on top of the stack" do
      before :each do
        vertical_if_program('0')
      end

      it "should move the program counter down" do
        @stack.pop.should == 5
      end
    end

    describe "with a non-zero value on top of the stack" do
      before :each do
        vertical_if_program('2')
      end

      it "should move the program counter up" do
        @stack.pop.should == 4
      end
    end
  end

  describe "controlling the program counter direction" do
    describe "to the up direction" do
      before :each do
        run_program(["  ^@",
                     "  @",
                     "  7"])
      end

      it "should set the program counter direction to :up" do
         @pc.direction.should == :up
      end

      it "should move upwards and loop to the bottom of the program" do
        @stack.pop.should == 7
      end
    end

    describe "to the down direction" do
      before :each do
        run_program(["v8@",
                     " @ ",
                     ">v@"])
      end

      it "should set the program counter direction to :down" do
        @pc.direction.should == :down
      end

      it "should move downwards and loop to the top of the program" do
        @stack.pop.should == 8
      end
    end

    describe "to the left direction" do
      before :each do
        run_program(["<@5"])
      end

      it "should set the program counter direction to :left" do
        @pc.direction.should == :left
      end

      it "should move left and loop to the right side of the program" do
        @stack.pop.should == 5
      end
    end

    describe "to the right direction" do
      describe "as the default direction" do
        before :each do
          run_program(["   1@"])
        end

        it "should set the program counter direction to :right" do
          @pc.direction.should == :right
        end

        it "should move right when a program starts" do
          @stack.pop.should == 1
        end
      end

      describe "and reaching the edge of the program" do
        before :each do
          run_program(["     v ",
                       "2@   > ",
                       "     @ "])
        end

        it "should move right and loop to the left side of the program" do
          @stack.pop.should == 2
        end
      end
    end

    describe "in a random direction" do
      before :each do
        srand(3)  # force predictable 'random' numbers, will always choose :up first
        run_program(["v@ ",
                     ">?@",
                     " @ "])
      end

      it "should set the program counter direction based on the random number" do
        @pc.direction.should == :up
      end
    end
  end
end


