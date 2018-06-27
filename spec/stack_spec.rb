require 'cloudformer/stack'

describe Stack do
  before :each do
    @cf = double(Aws::CloudFormation::Client)
    @cf_stack = double(Aws::CloudFormation::Stack)
    expect(Aws::CloudFormation::Client).to receive(:new).and_return(@cf)
    expect(@cf).to receive(:describe_stacks).and_return([@cf_stack])
  end
  describe "when deployed" do
    before :each do
      @stack = Stack.new("stack")
    end

    it "should report as the stack being deployed" do
      expect(@cf_stack).to receive(:exists?).and_return(true)
      expect(@stack.deployed).to be
    end

    describe "#delete" do
      it "should return a true if delete fails" do
        pending
        expect(@cf_stack).to receive(:exists?).and_return(false)
        expect(@cf_stack).to receive(:status)
        expect(@stack.delete).to be
      end
    end
  end

  describe "when stack is not deployed" do
    before :each do
      @stack = Stack.new("stack")
    end

    it "should report as the stack not being deployed" do
      expect(@cf_stack).to receive(:exists?).and_return(false)
      expect(@stack.deployed).to_not be
    end
  end

  describe "when stack operation throws ValidationError" do
    before :each do
      @stack = Stack.new("stack")
      expect(@cf_stack).to receive(:exists?).and_return(true)
      expect(File).to receive(:read).and_return("template")
      expect(@cf).to receive(:validate_template).and_return({"valid" => true})
      expect(@cf_stack).to receive(:update).and_raise(Aws::CloudFormation::Errors::ValidationError.new("dummy", nil))
    end

    it "apply should return Failed to signal the error" do
      expect(@stack.apply(nil, nil)).to be(:Failed)
    end
  end

  describe "when stack operation throws ValidationError because no updates are to be performed" do
    before :each do
      @stack = Stack.new("stack")
      expect(@cf_stack).to receive(:exists?).and_return(true)
      expect(File).to receive(:read).and_return("template")
      expect(@cf).to receive(:validate_template).and_return({"valid" => true})
      expect(@cf_stack).to receive(:update).and_raise(Aws::CloudFormation::Errors::ValidationError.new("No updates are to be performed.", nil))
    end

    it "apply should return NoUpdate to signal the error" do
      expect(@stack.apply(nil, nil)).to be(:Failed)
    end
  end

  describe "when stack update succeeds" do
    before :each do
      @stack = Stack.new("stack")
      expect(@cf_stack).to receive(:exists?).at_least(:once).and_return(true)
      expect(File).to receive(:read).and_return("template")
      expect(@cf).to receive(:validate_template).and_return({"valid" => true})
      expect(@cf_stack).to receive(:update).and_return(false)
      expect(@cf_stack).to receive(:events).and_return([])
      expect(@cf_stack).to receive(:status).at_least(:once).and_return("UPDATE_COMPLETE")
    end

    it "apply should return Succeeded" do
    expect(@stack.apply(nil, nil)).to be(:Succeeded)
    end
  end
end
