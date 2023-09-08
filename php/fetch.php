<?php
/*
 * 具有和js中fetch函数类似api的curl封装
*/
function fetch($url, $options = array()) {
    $ch = curl_init();

    // URL
    curl_setopt($ch, CURLOPT_URL, $url);

    // Method
    $method = isset($options['method']) ? strtoupper($options['method']) : 'GET';
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, $method);
    
    // Body
    if ($method === 'POST' || $method === 'PUT' || $method === 'PATCH') {
        if (isset($options['body'])) {
            curl_setopt($ch, CURLOPT_POSTFIELDS, $options['body']);
        }
    }

    // Headers
    if (isset($options['headers'])) {
        $headers = array();
        foreach ($options['headers'] as $key => $value) {
            $headers[] = "$key: $value";
        }
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    }

    // Redirect handling
    if (isset($options['follow_redirects']) && $options['follow_redirects'] === true) {
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        curl_setopt($ch, CURLOPT_MAXREDIRS, isset($options['max_redirects']) ? $options['max_redirects'] : 5);
    }

    // HTTPS Support
    if (strpos($url, 'https://') === 0) {
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    }

    // Custom options
    if (isset($options['custom_options']) && is_array($options['custom_options'])) {
        foreach ($options['custom_options'] as $option => $value) {
            curl_setopt($ch, $option, $value);
        }
    }

    // Timeout settings
    $timeout = isset($options['timeout']) ? $options['timeout'] : 30;
    curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, $timeout);

    // Response
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HEADER, true);

    $response = curl_exec($ch);
    $error = curl_error($ch);

    curl_close($ch);

    if ($error) {
        return false; // Handle error here
    }

    return new FetchResponse($response);
}


class FetchResponse {
    private $content;
    private $headers;
    private $status;
    private $statusText;

    public function __construct($response) {
        list($headers, $content) = explode("\r\n\r\n", $response, 2);
        $this->headers = $headers;

        preg_match('/HTTP\/\d\.\d\s+(\d+)\s+(.*)/', $headers, $matches);
        $this->status = $matches[1];
        $this->statusText = $matches[2];

        $this->content = $content;
    }

    public function json() {
        return json_decode($this->content, true);
    }

    public function text() {
        return $this->content;
    }

    public function status() {
        return $this->status;
    }

    public function statusText() {
        return $this->statusText;
    }

    public function headers() {
        $headers = preg_replace('/HTTP\/\d\.\d\s+\d+\s+.*/', '', $this->headers);
        return trim($headers);
    }
}

// // Usage examples
// $url = 'https://us.iapp.run/echo';
// $options = array(
//     'method' => 'POST',
//     'headers' => array(
//         'Content-Type' => 'application/json'
//     ),
//     'body' => json_encode(array(
//         'title' => 'New Post',
//         'body' => 'This is the content of the new post.',
//         'userId' => 1
//     )),
//     'follow_redirects' => true, // Follow redirects
//     'custom_options' => array(
//         CURLOPT_FOLLOWLOCATION => true // Example of custom option
//     ),
//     'timeout' => 10 // Example of timeout setting
// );

// $response = fetch($url, $options);

// // Handle response ...


// // Get JSON data
// // $jsonData = $response->json();
// // print_r($jsonData);

// // Get status code
// echo "Status Code: " . $response->status() . "\n";

// // Get status text
// echo "Status Text: " . $response->statusText() . "\n";

// // Get headers
// echo "Headers:\n" . $response->headers() . "\n";

// // Get text content
// echo $response->text();

$data = ['title' => 'New Post', 'body' => 'This is the content of the new post.', 'userId' => 1];
$response_text = fetch("https://us.iapp.run/echo",  ['method' => 'POST', 'headers' => ['Content-Type' => 'application/json'], 'body' => json_encode($data)])->text();
print_r($response_text);