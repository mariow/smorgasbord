<?php

if (!$_POST['service_name']) exit;

$priolist = array('OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2);
$priority = array_key_exists($_POST['check_result'], $priolist)
        ? $priolist[$_POST['check_result']]
        : 1;

$url =  'https://prowl.weks.net/publicapi/add'.
        '?apikey=<apikey>'.
        '&priority='.$priority.
        '&application=Serverguard'.
        '&event='.urlencode(
                $_POST['check_result'].' '.
                $_POST['service_name'].' ('.
                $_POST['service_shortname'].') auf '.
                $_POST['server_name']
        ).
        '&description='.urlencode($_POST['notification_time'].': '.$_POST['check_output']);

echo $url;
$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_exec($ch);
curl_close($ch);

?>
