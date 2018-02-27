(function() {
	var kafka = require('node-rdkafka');
	var Promise = require('bluebird');
	var producer;
	var producerReady;

	var closeProducer = function() {
		producer.disconnect();
	};

	var bindListeners = function() {
		producer.on('error', function(err) {
			console.log(err);
			closeProducer();
		});
		producer.on('SIGTERM', function() {
			closeProducer();
		});
		producer.on('delivery-report', function(report) {
			// console.log(report);
		});
		producerReady = new Promise(function(resolve, reject) {
			producer.on('ready', function() {
				resolve(producer);
			});
		});
	};

	var initializeProducer = function() {
		producer = new kafka.Producer({
		    'client.id': 'kafka',
		    'metadata.broker.list': 'localhost:9092',
		    'compression.codec': 'gzip',
		    'retry.backoff.ms': 200,
		    'message.send.max.retries': 10,
		    'socket.keepalive.enable': true,
		    'queue.buffering.max.messages': 100000,
	            'queue.buffering.max.ms': 1000,
		    'batch.num.messages': 1000000,
		    'dr_cb': true
		});

		producer.connect({}, function(err) {
		    if (err) {
		    	console.log(err);
		    	return process.exit(1);
		   	};
		});

		bindListeners();
	};

	var KafkaService = function() {
		initializeProducer();
	};

	KafkaService.prototype.sendMessage = function(payload) {
		producerReady.then(function(producer) {
			producer.produce(payload, function(err) {
				if (err) {
					console.log(err);
				};
			});
		});
	};

	module.exports = KafkaService;
})();