const express = require('express');
const request = require('request');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.raw({ type: '*/*' }));

app.all('/', (req, res) => {
    const url = req.query.url;

    if (url) {
        const headers = { ...req.headers };
        const headersToRemove = ['host'];

        headersToRemove.forEach(header => delete headers[header]);

        headers['Cache-Control'] = 'no-cache';

        let bodyData = req.body;
        if (typeof bodyData !== 'string' && !Buffer.isBuffer(bodyData)) {
            // Convert bodyData to a string or Buffer
            bodyData = JSON.stringify(bodyData); // Or any other suitable conversion
        }

        const options = {
            method: req.method,
            url: url,
            headers: headers,
            body: bodyData,
            followRedirect: true,
            strictSSL: false,
            timeout: 600
        };

        request(options, (error, response, body) => {
            if (error) {
                res.status(500).send(`Error occurred: ${error}`);
            } else {
                const headersToForward = ['Content-Type', 'Content-Length', 'Content-Encoding', 'Transfer-Encoding', 'Cache-Control'];

                Object.entries(response.headers).forEach(([key, value]) => {
                    if (headersToForward.includes(key)) {
                        res.setHeader(key, value);
                    }
                });

                res.setHeader('Access-Control-Allow-Origin', '*');
                res.status(response.statusCode).send(body);
            }
        });
    } else {
        res.status(400).send('URL is empty');
    }
});

const port = 3000;
app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});
