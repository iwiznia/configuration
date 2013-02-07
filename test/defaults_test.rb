require 'minitest/autorun'
require 'configuration.rb'

describe Configuration do
  before do
    @a = Configuration.for('a') {
      some "thing"
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
    }

    @c = Configuration.for('c', 'b') {
      foo 'bar'
      nesting {
        one -1
        three 3
      }
    }
  end

  it "must return default values" do
    @b.some.must_equal @a.some
    @c.some.must_equal @a.some
    @b.host.must_equal @c.host
    @b.mail.must_equal @c.mail
    @b.mail.host.must_equal @c.mail.host
    @b.nesting.two.must_equal @c.nesting.two
    @c.nesting.one.must_equal -1
    @c.nesting.three.must_equal 3
  end

  it "must get configuration by constant" do
    assert @c === Configuration::C
  end
end