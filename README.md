# MetricHandler

Receives metric events from an SQS queue and posts current metrics to a HTTP endpoint.

[![Build Status](https://travis-ci.org/meducation/metric_handler.png)](https://travis-ci.org/meducation/metric_handler)
[![Dependencies](https://gemnasium.com/meducation/metric_handler.png?travis)](https://gemnasium.com/meducation/metric_handler)
[![Code Climate](https://codeclimate.com/github/meducation/metric_handler.png)](https://codeclimate.com/github/meducation/metric_handler)
[![Coverage Status](https://coveralls.io/repos/meducation/metric_handler/badge.png)](https://coveralls.io/r/meducation/metric_handler)

## Installation

Add this line to your application's Gemfile:

    gem 'metric_handler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install metric_handler

## Running the Server

Firstly create a configuration file by copying config.yml.example to config.yml.

```
cp config.yml.example config.yml
```

The following example must be replaced with valid values in config.yml.

```
access_key: aws-access-key
secret_key: aws-secret-key
queue_region: aws-region
application_name: application-name
topic: topic
```

This configures metric handler to use your AWS account and tells it which 
SQS queue to read messages from.

The dashboard-url is optional. If it is specified, metric_handler will
perform a HTTP POST to the url with details of metrics and events received.
Posts will be made to dashboard-url/metrics/traffic and
dashboard-url/events. If dashboard-url is not specified, no HTTP POST's
will be performed.

Once configured, metric handler is run using the command:

```
./bin/metric_handler
```

Now that metric_handler is listening for messages on an AWS SQS queue, you
need to add messages to the queue. You can do this using udp2sqs_server and
udp2sqs_client.

Configure the udp2sqs_server to post messages to the same AWS SQS queue.
This is done by copying is queue.yml.example file to queue.yml and
entering the same AWS details as entered into metric_handlers config.yml
file. Then run the udp2sqs_server using the command:

```
./bin/udp2sqs localhost 9732
```

The udp2sqs server will now post messages to the AWS queue when it receives
a UDP message on port 9732.

Use the udp2sqs_client project to send a UDP messages to the server. This
requires no configuration, simply run the following command from the
udp2sqs_client project.

```
ruby ./bin/send.rb 1234
```

This will send a UDP message indicating a page view for a user with the
session_id 1234. This message will be forwarded by the udp2sqs_server,
via the SQS queue, to the metric_handler.

## Contributing

Firstly, thank you!! :heart::sparkling_heart::heart:

Please read our [contributing guide](https://github.com/meducation/udp2sqs-client/tree/master/CONTRIBUTING.md) for information on how to get stuck in.

## Licence

Copyright (C) 2013 New Media Education Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

A copy of the GNU Affero General Public License is available in [Licence.md](https://github.com/meducation/udp2sqs-client/blob/master/LICENCE.md)
along with this program.  If not, see <http://www.gnu.org/licenses/>.
