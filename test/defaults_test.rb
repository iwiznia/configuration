require 'minitest/autorun'
require 'lib/configuration.rb'
#require 'ruby-debug' ; Debugger.start

describe Configuration do
  before do
    @a = Configuration.for('a') {
      some "thing"
      nesting {
        testing "this"
      }
      none false
      a_hash({:value => 1})
      a_hash_with_strings({"value" => 2})
      not_inherited {
        one 1
      }
    }

    @b = Configuration.for('b', @a) {
      host "codeforpeople.com"

      mail {
        host "gmail.com"
      }

      nesting {
        one 1
        two 2
      }
      evaluated_code Proc.new { Time.now }
      not_inherited {
        two 2
      }
    }

    @c = Configuration.for('c', 'b') {
      foo 'bar'
      nesting {
        one -1
        three 3
      }
      not_inherited(true) {
        three 3
      }
    }
  end

  it "must return default values" do
    ev = @b.evaluated_code
    @a.none.must_equal false
    @a.a_hash.must_equal({:value => 1})
    @a.a_hash_with_strings.must_equal({"value" => 2})
    @a.nesting.testing.must_equal "this"
    @b.nesting.one.must_equal 1
    @b.nesting.testing.must_equal "this"
    @a.to_hash.must_equal({:some => "thing", :nesting => {:testing => "this"}, :none => false, :a_hash => {:value => 1}, :a_hash_with_strings => {"value" => 2}, :not_inherited => {:one => 1}})
    @b.some.must_equal @a.some
    @c.some.must_equal @a.some
    @b.host.must_equal @c.host
    @b.mail.to_hash.must_equal @c.mail.to_hash
    @b.mail.host.must_equal @c.mail.host
    @b.nesting.two.must_equal @c.nesting.two
    @c.nesting.one.must_equal -1
    @c.nesting.three.must_equal 3
    lambda {@c.nesting.foo}.must_raise Configuration::Error
    @c.evaluated_code.wont_equal ev
  end

  it "must get configuration by constant" do
    assert @c === Configuration::C
  end

  it "must check the config has key" do
    @c.respond_to?(:not_exists).must_equal false
    @c.respond_to?(:foo).must_equal true
    @c.respond_to?(:some).must_equal true
  end

  it 'must not use the inherited value if true param is passed' do
    @c.not_inherited
    @c.not_inherited.three.must_equal 3
    @c.not_inherited.respond_to?(:two).must_equal false
  end
end