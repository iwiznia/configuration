require 'minitest/autorun'
require 'configuration.rb'

describe Configuration do

  before do
    # similar to config/sample d.rb
    Configuration.for('d'){
      built_in_inspect Send('inspect')
      index 'some'
      id "anid"
    }

    @c = Configuration.for 'd'
  end

  it "must overwrite built-in methods" do
    @c.index.must_equal 'some'
    #@c.inspect.wont_equal @c.built_in_inspect
    @c.id.must_equal 'anid'
  end

end
