Undo
==========
[![Build Status](https://travis-ci.org/AlexParamonov/undo-serializer-active_model.png?branch=master)](https://travis-ci.org/AlexParamonov/undo-serializer-active_model)
[![Gemnasium Build Status](https://gemnasium.com/AlexParamonov/undo-serializer-active_model.png)](http://gemnasium.com/AlexParamonov/undo-serializer-active_model)
[![Coverage Status](https://coveralls.io/repos/AlexParamonov/undo-serializer-active_model/badge.png?branch=master)](https://coveralls.io/r/AlexParamonov/undo-serializer-active_model?branch=master)
[![Gem Version](https://badge.fury.io/rb/undo-serializer-active_model.png)](http://badge.fury.io/rb/undo-serializer-active_model)
[![Code Climate](https://codeclimate.com/github/AlexParamonov/undo-serializer-active_model.png)](https://codeclimate.com/github/AlexParamonov/undo-serializer-active_model)

ActiveModel serializer for Undo gem. Does not require anything from Rails so is friendly to use with POROs.

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

Most likely you'll install undo gem as well:

    $ gem install undo

Requirements
------------
1. Ruby >= 1.9

Usage
------------

Gem is designed to be used with Undo gem.  
Customize Undo to use serializer in global configuration:

``` ruby
Undo.configure do |config|
  config.serializer = Undo::Serializer::ActiveModel.new
end
```

Custom primary_key set, find_or_initialize and persist `Proc`s could be provided to the adapter:
``` ruby
Undo.configure do |config|
  config.serializer = Undo::Serializer::ActiveModel.new(
      primary_key: [:id, :status],
      find_or_initialize: ->(object_class, pk_attributes) { object_class.find_or_initialize_by pk_attributes },
      serialize_attributes: ->(object) { object.serializable_hash },
      persist: ->(object) { object.save! },
    )
end
```

For ActiveRecord Undo uses reasonable defaults, so most of the time it is not needed to overwrite them.
It should work with most Virtus objects as well.

As usual any Undo configuration may be set in place on store, wrap and restore:
``` ruby
Undo.store user, serializer: Undo::Serializer::ActiveRecord.new(primary_key: :uuid)
Undo.restore uuid, primary_key: :uuid, persist: ->(object) { object.write_to_disk! }
```

### Associations

Add `include` option to serialize the association
``` ruby
uuid = Undo.store post, include: comments
Undo.restore uuid
```

Will restore post with related comments.

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
