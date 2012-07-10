# Front End Loader

Front End Loader is a Ruby DSL for declaring load tests. It works in the spirit of
tools like JMeter, by simulating a number of users performing a scripted set of actions
and displaying metrics about response times and error rates as the requests are performed.
Unlike GUI tools like JMeter, however, front_end_loader makes it very simple to declare
your requests and to pass data between requests, by looking at the responses to gather data.

## Install
    gem install front_end_loader

## Creating an Experiment

In order to create a test, just declare a FrontEndLoader::Experiment object:

```ruby
require 'front_end_loader'

experiment = FrontEndLoader::Experiment.new.tap do |e|
  e.user_count = 20
  e.loop_count = 5
  e.domain = 'https://www.brewster.com'
  e.basic_auth('unreal_login', 'unreal_password')
  e.default_parameters = { '_subdomain' => 'api' }
  e.debug = '/tmp/front_end_loader.txt'

  e.requests do |r|
    ...
  end
end

experiment.run
```

This block declares an experiment that:

* simulates 20 users simultaneously interacting with the system
* executes the request script five times per user before exiting. You can specify infinite loops by either not calling loop_count or passing -1
* will operate against the brewster.com domain
* uses http basic auth
* passes a default parameter of _subdomain to each request, and
* writes debugging output to /tmp/front_end_loader.txt

It then runs the experiment, which causes the requests to start flowing and output to be displayed
on the screen. The requests method on the experiment is where you will define the script to be run
loop_count times for each of the simulated users:

```ruby
  e.requests do |r|

    contact_id = nil

    r.get('contacts', '/v0/search', :page => rand(15) + 1, :per_page => 30) do |response|
      parsed = Yajl::Parser.parse(response.body)
      contacts = parsed['contacts']
      contact_id = contacts[rand(contacts.length)]['id']
    end

    r.get('profile', "/v0/contacts/#{contact_id}")

    r.post('add to favorites', "/v0/contacts/#{contact_id}/favorite")
  end
```

For each request, arguments are:

* the label to use when tracking it in the display
* the path
* parameters, as a hash
* for post and put requests, a data object to use as the request body

All request declarations can take a block that will be passed the response from that request. The response
is a Patron::Response object and can be used to access data and pass it into further requests. Each iteration
of the script will be run in order and will not affect other iterations that may be running.

## Running the experiment

Excuting an experiment will produce output like this:

```
```

This display accepts the following keyboard controls:

* c - reset the data
* d - write the contents of the screen to the debug file
* p - pause the scripts, so the data will remain static and no requests will be made
* s - start the scripts again when paused

## <a name="copyright"></a>Copyright
Copyright (c) 2012 Aubrey Holland
See [LICENSE](https://github.com/brewster/front_end_loader/blob/master/LICENSE) for details.
