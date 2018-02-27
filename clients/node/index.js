var Kafka = require('node-rdkafka');
console.log(Kafka.librdkafkaVersion);
console.log(Kafka.features);

var closeProducer = function() {
		producer.disconnect();
};

var producer = new Kafka.Producer({
			'debug' : 'all',
		    'client.id': 'kafka',
		    'metadata.broker.list': 'kafka.docker.ssl:9094',
		    'retry.backoff.ms': 200,
		    'message.send.max.retries': 10,
		    'socket.keepalive.enable': true,
		    'queue.buffering.max.messages': 100000,
	        'queue.buffering.max.ms': 1000,
		    'batch.num.messages': 1000000,
		    'dr_cb': true,
		    'security.protocol': 'ssl',
		    'ssl.ca.location': '../../certs/client.ca-bundle.crt',
		    'ssl.certificate.location': '../../certs/client.pem',
		    'ssl.key.location': '../../certs/client.key',
		    'ssl.key.password': 'kafkadocker',
		});

producer.connect({}, function(err) {
    if (err) {
    	console.log(err);
    	return process.exit(1);
   	};
});

// Wait for the ready event before proceeding
producer.on('ready', function() {
  try {

  	console.log("Sending message");

    producer.produce(
      // Topic to send the message to
      'test',
      // optionally we can manually specify a partition for the message
      // this defaults to -1 - which will use librdkafka's default partitioner (consistent random for keyed messages, random for unkeyed messages)
      null,
      // Message to send. Must be a buffer
      new Buffer('TEST NODE'),
      // for keyed messages, we also specify the key - note that this field is optional
      'Stormwind',
      // you can send a timestamp here. If your broker version supports it,
      // it will get added. Otherwise, we default to 0
      Date.now(),
      // you can send an opaque token here, which gets passed along
      // to your delivery reports
    );
  } catch (err) {
    console.error('A problem occurred when sending our message');
    console.error(err);
    closeProducer();
  }
});
 
// Poll for events every 100 ms
producer.setPollInterval(100);
 
producer.on('delivery-report', function(err, report) {
  // Report of delivery statistics here:
  //
  console.log(report);
  closeProducer();
});

producer.on('disconnected', function(err, report) {
  process.exit(0);
});

// Any errors we encounter, including connection errors
producer.on('event.error', function(err) {
  console.error('Error from producer');
  console.error(err);
})
