Undo
==========
[![Build Status](https://travis-ci.org/AlexParamonov/undo-serializer-active_model.png?branch=master)](https://travis-ci.org/AlexParamonov/undo-serializer-active_model)
[![Gemnasium Build Status](https://gemnasium.com/AlexParamonov/undo-serializer-active_model.png)](http://gemnasium.com/AlexParamonov/undo-serializer-active_model)
[![Coverage Status](https://coveralls.io/repos/AlexParamonov/undo-serializer-active_model/badge.png?branch=master)](https://coveralls.io/r/AlexParamonov/undo-serializer-active_model?branch=master)
[![Gem Version](https://badge.fury.io/rb/undo-serializer-active_model.png)](http://badge.fury.io/rb/undo-serializer-active_model)

ActiveModel serializer for Undo gem.

Designed to be used with `gem "active_model_serializers"`, but does not depends on it.

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
1. `activesupport` (`active_model_serializers` depends on it)

Usage
------------

Gem is designed to be used with Undo gem.  
Add it in global config:

``` ruby
Undo.configure do |config|
  config.serializer = Undo::Serializer::ActiveModel.new
end
```

Custom serializer could be provided to the adapter:
``` ruby
Undo.configure do |config|
  config.serializer = 
    Undo::Serializer::ActiveModel.new serializer: ->(object) { "#{object.class.name}UndoSerializer".constantize.new(object) }
end
```

Or it may be initialized by serializer instance:
``` ruby
Undo.configure do |config|
  config.serializer = 
    Undo::Serializer::ActiveModel.new CustomSerializer.new
end
```

As usual any Undo configuration may be set in place on wrap and restore:
``` ruby
Undo.wrap user, serializer: Undo::Serializer::ActiveModel.new
Undo.restore uuid, serializer: Undo::Serializer::ActiveModel.new
```

In place using the specific serializer from `gem "active_model_serializers"`:
``` ruby
Undo.wrap user, serializer: Undo::Serializer::ActiveModel.new(UserSerializer.new(user))
```

### Associations

It is required to set `somethig___association_class_name` as `key` in `active_model_serializer`:
``` ruby
class UserSerializer < ActiveModel::Serializer
  attributes *User.attribute_names.map(&:to_sym)
  has_many :roles, key: :has_many___roles
end
```


Contacts
-------------
Have questions or recommendations? Contact me via `alexander.n.paramonov@gmail.com`

Found a bug or have enhancement request? You are welcome at [Github bugtracker](https://github.com/AlexParamonov/undo-serializer-active_model/issues)


Compatibility
-------------
tested with Ruby:

* 2.1
* 2.0
* 1.9.3
* ruby-head
* rbx-2
* jruby-19mode
* jruby-head

and ActiveRecord:

* 3.0
* 3.1
* 3.2
* 4.0
* 4.1

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
