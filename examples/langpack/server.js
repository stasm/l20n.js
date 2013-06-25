var http = require('http');

var available = {
  localhost: ['de']
}

var resources = {
  localhost: {
    de: {
      'locales/de.lol': '<foo "Das Foo">'
    }
  }
}

http.createServer(function (req, res) {
  res.writeHead(200, {
    'Content-Type': 'text/plain',
    'Access-Control-Allow-Origin': '*'
  });
  res.end(JSON.stringify(available, null, 2));
}).listen(8013);

