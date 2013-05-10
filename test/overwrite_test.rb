require 'minitest/autorun'
require 'configuration.rb'

describe Configuration do

  before do
    # similar to config/sample d.rb
    Configuration.for('d'){
      built_in_inspect Send('inspect')
      inspect 'forty-two'
      id "anid"
    }

    @c = Configuration.for 'd'
  end

  it "must overwrite built-in methods" do
    @c.inspect.must_equal 'forty-two'
    @c.inspect.wont_equal @c.built_in_inspect
    @c.id.must_equal 'anid'
  end

end
