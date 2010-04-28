#!/usr/bin/php
<?php

$apikey = '...';
$file = array_pop($argv);
$msg = urlencode($file.' ('.$_ENV['UPLOAD_SIZE'].' bytes)');

$url =  'https://prowl.weks.net/publicapi/add'.
        '?apikey='.$apikey.;
        '&priority='.$priority.
        '&application=FTP'.
        '&event='.urlencode('New file from '.$_ENV['UPLOAD_USER']).
        '&description='.$msg;

echo $url;
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_exec($ch);
curl_close($ch);

?>
