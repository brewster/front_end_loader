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
------------------------------------------------------------------------------------------------------
| call                           | count    | avg time | max time | errors   | error %  | throughput  |
------------------------------------------------------------------------------------------------------
| profile                        | 40       | 0.252    | 0.731    | 0        | 0.0      | 140         |
| random search                  | 40       | 0.275    | 0.491    | 0        | 0.0      | 140         |
| filtered_search                | 40       | 0.28     | 0.67     | 0        | 0.0      | 140         |
| suggestions                    | 40       | 0.264    | 0.624    | 0        | 0.0      | 140         |
| autocomplete                   | 38       | 0.234    | 0.456    | 0        | 0.0      | 133         |
| filtered autocomplete          | 37       | 0.204    | 0.323    | 0        | 0.0      | 130         |
| services                       | 37       | 0.203    | 0.476    | 0        | 0.0      | 130         |
| service types                  | 37       | 0.185    | 0.456    | 0        | 0.0      | 130         |
| me                             | 36       | 0.25     | 0.555    | 0        | 0.0      | 126         |
|                                |          |          |          |          |          |             |
| TOTAL                          | 345      | 0.238    | 0.731    | 0        | 0.0      | 1209        |
------------------------------------------------------------------------------------------------------
run time: 0:00:17
```

Throughput is measured in requests per minute and note that because each "user" is running though the script
in series, the throughput for an individual request is not as high as you would expect by running only that request
over and over again.

This display accepts the following keyboard controls:

* c - reset the data
* d - write the contents of the screen to the debug file
* p - pause the scripts, so the data will remain static and no requests will be made
* q - quit
* s - start the scripts again when paused

## <a name="copyright"></a>Copyright
Copyright (c) 2012 Aubrey Holland
See [LICENSE](https://github.com/brewster/front_end_loader/blob/master/LICENSE) for details.
