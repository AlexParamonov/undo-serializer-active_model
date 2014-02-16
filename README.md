Undo
==========
[![Build Status](https://travis-ci.org/AlexParamonov/undo-serializer-active_model.png?branch=master)](https://travis-ci.org/AlexParamonov/undo-serializer-active_model)
[![Gemnasium Build Status](https://gemnasium.com/AlexParamonov/undo-serializer-active_model.png)](http://gemnasium.com/AlexParamonov/undo-serializer-active_model)
[![Coverage Status](https://coveralls.io/repos/AlexParamonov/undo-serializer-active_model/badge.png?branch=master)](https://coveralls.io/r/AlexParamonov/undo-serializer-active_model?branch=master)
[![Gem Version](https://badge.fury.io/rb/undo-serializer-active_model.png)](http://badge.fury.io/rb/undo-serializer-active_model)

ActiveModel serializer for Undo gem.

Contents
---------
1. Installation
1. Requirements
1. Contacts
1. Compatibility
1. Contributing
1. Copyright

Installation
------------

Add this line to your application's Gemfile:

    gem 'undo-serializer-active_model'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install undo-serializer-active_model

Requirements
------------
1. Ruby >= 1.9
1. `active_model_serializers` "~> 0.8"
1. `activesupport` (`active_model_serializers` depends on it too)

Usage
------------

It is required to set `somethig___association_class_name` as `key` in `active_model_serializer`:
``` ruby
class UserSerializer < ActiveModel::Serializer
  attributes *User.attribute_names.map(&:to_sym)
  has_many :roles, key: :has_many___roles
end
```

Gem is designed to be used with Undo gem.  
Add it in global config:

``` ruby
Undo.configure do |config|
  config.serializer = Undo::Serializer::ActiveModel.new
end
```

or use in place:
``` ruby
Undo.wrap user, serializer: Undo::Serializer::ActiveModel.new
Undo.restore uuid, serializer: Undo::Serializer::ActiveModel.new
```

In place using the specific serializer from `gem active_model_serializers`:
``` ruby
Undo.wrap user, serializer: Undo::Serializer::ActiveModel.new(UserSerializer.new(user))
```


Contacts
-------------
Have questions or recommendations? Contact me via `alexander.n.paramonov@gmail.com`
Found a bug or have enhancement request? You are welcome at [Github bugtracker](https://github.com/AlexParamonov/undo-serializer-active_model/issues)


Compatibility
-------------
tested with Ruby

* 2.1
* 2.0
* 1.9.3
* ruby-head
* rbx
* jruby-19mode
* jruby-head

See [build history](http://travis-ci.org/#!/AlexParamonov/undo-serializer-active_model/builds)


## Contributing

1. Fork repository ( http://github.com/AlexParamonov/undo-serializer-active_model/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright
---------
Copyright © 2014 Alexander Paramonov.
Released under the MIT License. See the LICENSE file for further details.
