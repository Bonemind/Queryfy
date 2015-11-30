# Queryfy [![Build Status](https://travis-ci.org/Bonemind/Queryfy.svg?branch=master)](https://travis-ci.org/Bonemind/Queryfy)  [![Dependency Status](https://gemnasium.com/Bonemind/Queryfy.svg)](https://gemnasium.com/Bonemind/Queryfy)

Queryfy is a gem that allows you to simply and easily paginate and filter activerecord models using queryparams.
The gem assumes you pass it a hash of queryparams which contain a filterstring in `filter`, and optionally `offset` and `limit` fields.

Queryfy uses a filterstring to query models that supports nesting of conditions, e.g:
```
name=="name"&&(desc="desc"||(isbn=2||isbn=4))||author=~"%orwell%"
```

This gem uses [FilterLexer](https://github.com/MaienM/FilterLexer/) to parse the filterstring

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'queryfy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install queryfy

## Usage

### General
```
require 'queryfy'

class SomeModel
    include Queryfy
end

SomeModel.queryfy(queryparams)
```

The gem adds makes a `queryfy` method available to ActiveRecord::Base when included.
The queryfy method takes a hash in the following format:
```
{'filter': 'name=="name", 'offset': 50, 'limit': 10}
```
All three are optional, and any extra values are ignored.

Defaults:
```
offset = 0
limit = 50
```

If filter is either nil or empty, queryfy will assume everything should be selected, almost like `SomeModel.all`

After calling `queryfy` you will get back the following:
```
{data: [your data], count: total results, offset: the offset used, limit: the limit used}
```

### Exceptions

All exceptions queryfy can raise inherit from `QueryfyError`

Currently, the following exceptions exist:
```
FilterParseError: Occurs when filter_lexer fails to parse the filter_query
NoSuchFieldError: Occurs when trying to filter on a nonexistant column
```

### Querystrings

Queryfy supports arbitratily deeply nested conditions in filters, and uses
`filter_lexer` under the hood to parse the filter strings

Examples:
```
//SQL: name = 'name'
name=="name" 

//SQL: name = 'name' AND description = 'desc'
name=="name"&&description=="desc"

//SQL: name = 'name' AND (description = 'desc1' OR isb = 1234)
name=="name"&&(description=="desc1"||isbn=1234)

//SQL: name = 'name' AND (description = 'desc1' OR isb = 1234) OR name != 'somename'
name=="name"&&(description=="desc1"||isbn=1234)||name!="somename"

//SQL: name = 'name' AND (description = 'desc1' OR (isb = 1234 || isbn = 5678))
name=="name"&&(description=="desc1"||(isbn=1234||isbn=5678))
```

### Operators

Since queryfy builds on filter_lexer it supports all operators filter lexer supports:
```
Equal: ==, eq, EQ, is, IS
Not equal: !=, <>, neq, NEQ, not is, NOT IS, is not, IS NOT
Less than: <, lt, LT
Less or equal: <=, le, LE
greater than: >, gt, GT
Greated than or equal: >=, ge, GE
Like: =~, like, LIKE
Not like: !=~, not like, NOT LIKE
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Bonemind/queryfy.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

