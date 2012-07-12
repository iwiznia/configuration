require 'minitest/autorun'
require 'configuration.rb'

describe Configuration do

  before do
    @b = Configuration.for('b') {
      host "codeforpeople.com"

      mail {
        host "gmail.com"
      }
    }

    @c = Configuration.for('c', @b) {
      foo 'bar'
    }
  end

  it "must return default values" do
    @b.host.must_equal @c.host
    @b.mail.must_equal @c.mail
    @b.mail.host.must_equal @c.mail.host
  end

end
