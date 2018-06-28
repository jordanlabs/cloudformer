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
        allow(@cf_stack).to receive(:exists?).and_return(false)
        expect(@cf_stack.exists?).to eq(false)

        allow(@cf_stack).to receive(:status)
        expect(@cf_stack.status).to be_nil

        allow(@stack).to receive(:delete)
        expect(@stack.delete).to be_nil
      end
    end
  end

  describe "when stack is not deployed" do
    before :each do
      @stack = Stack.new("stack")
    end

    it "should report as the stack not being deployed" do
      allow(@cf_stack).to receive(:exists?).and_return(false)

      expect(@cf_stack.exists?).to eq(false)
      expect(@stack.deployed).to_not be
    end
  end

  describe "when stack operation throws ValidationError" do
    before :each do
      @stack = Stack.new("stack")
      allow(@cf_stack).to receive(:exists?).and_return(true)
      allow(File).to receive(:read).and_return("template")
      allow(@cf).to receive(:validate_template).and_return({"valid" => true})
      allow(@stack).to receive(:update)

      allow(@cf_stack).to receive(:update).and_raise(Aws::CloudFormation::Errors::ValidationError, "dummy")
    end

    it "apply should return Failed to signal the error" do
      allow(@cf_stack).to receive(:status).and_return("CREATE_FAILED")
      expect(@stack.apply(nil, nil)).to be(:Failed)
    end
  end

  describe "when stack operation throws ValidationError because no updates are to be performed" do
    before :each do
      @stack = Stack.new("stack")
      allow(@cf_stack).to receive(:exists?).and_return(true)
      allow(File).to receive(:read).and_return("template")
      allow(@cf).to receive(:validate_template).and_return({"valid" => true})
      allow(@cf_stack).to receive(:update).and_raise(Aws::CloudFormation::Errors::ValidationError.new(nil, "No updates are to be performed."))
    end

    it "apply should return NoUpdate to signal the error" do
      expect(@cf.validate_template).to eq({"valid" => true})
      expect(@stack.apply(nil, nil)).to eq(:NoUpdates)
    end
  end

  describe "when stack update succeeds" do
    before :each do
      @stack = Stack.new("stack")
      allow(@cf_stack).to receive(:exists?).at_least(:once).and_return(true)
      allow(File).to receive(:read).and_return("template")
      allow(@cf).to receive(:validate_template).and_return({"valid" => true})
      allow(@cf_stack).to receive(:update).and_return(false)
      allow(@cf_stack).to receive(:events).and_return([])
      allow(@cf_stack).to receive(:status).at_least(:once).and_return("UPDATE_COMPLETE")
    end

    it "apply should return Succeeded" do
      expect(@stack.apply(nil, nil)).to be(:Succeeded)
    end
  end
end
